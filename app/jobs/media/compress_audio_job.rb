# app/jobs/media/compress_audio_job.rb

module Media
  class CompressAudioJob < ApplicationJob
    queue_as :media

    retry_on MediaService::CompressionError, wait: :polynomially_longer, attempts: 3
    retry_on StorageService::Error, wait: :polynomially_longer, attempts: 3
    discard_on ActiveRecord::RecordNotFound

    def perform(asset_id:)
      @asset = Asset.find(asset_id)
      return if @asset.optimal? || @asset.max_compressed?

      @asset.mark_processing!
      broadcast_status_change(MediaConstants::Status::PROCESSING)

      input_path = download_from_storage
      original_bytes = File.size(input_path)
      compressed_path = MediaService::AudioCompressor.compress(input_path)
      compressed_bytes = File.size(compressed_path)

      if compressed_bytes >= original_bytes
        Rails.logger.info("[CompressAudioJob] Original (#{original_bytes} bytes) already optimal (compressed: #{compressed_bytes} bytes). Marking optimal immediately.")
        @asset.mark_optimal!
        broadcast_status_change(MediaConstants::Status::OPTIMAL)
        return
      end

      reduction_ratio = (original_bytes - compressed_bytes).to_f / original_bytes
      reupload_compressed(compressed_path)
      finalize_asset(compressed_path)
      Rails.logger.info("[CompressAudioJob] Compressed #{original_bytes} -> #{compressed_bytes} bytes for asset #{asset_id} (#{(reduction_ratio * 100).round(1)}% reduction)")

      if reduction_ratio < MediaConstants::MIN_REDUCTION_THRESHOLD
        Rails.logger.info("[CompressAudioJob] Asset #{asset_id} reduction (#{(reduction_ratio * 100).round(1)}%) below threshold. Marking optimal immediately.")
        @asset.mark_optimal!
        broadcast_status_change(MediaConstants::Status::OPTIMAL)
        return
      end

      count = @asset.increment_compression_count!

      if count >= MediaConstants::MAX_COMPRESSION_PASSES
        @asset.mark_optimal!
        broadcast_status_change(MediaConstants::Status::OPTIMAL)
      else
        @asset.mark_ready!
        broadcast_status_change(MediaConstants::Status::READY)
      end

      Rails.logger.info("[CompressAudioJob] Completed for asset #{asset_id} (pass #{count}/#{MediaConstants::MAX_COMPRESSION_PASSES})")
    rescue StandardError => e
      @asset&.mark_failed! if @asset&.persisted?
      broadcast_status_change(MediaConstants::Status::FAILED)
      Rails.logger.error("[CompressAudioJob] Failed for asset #{asset_id}: #{e.message}")
      raise
    ensure
      cleanup_temp_files
    end

    private

    def broadcast_status_change(status)
      return unless @asset

      event_type = case status
      when MediaConstants::Status::READY, MediaConstants::Status::OPTIMAL
                     MediaConstants::SocketEvent::ASSET_COMPRESSED
      when MediaConstants::Status::FAILED
                     MediaConstants::SocketEvent::ASSET_COMPRESSION_FAILED
      else
                     MediaConstants::SocketEvent::ASSET_COMPRESSING
      end

      payload = {
        type: event_type,
        asset_id: @asset.id,
        status: status,
        size_bytes: @asset.size_bytes,
        url: @asset.url
      }

      msg = case status
      when MediaConstants::Status::READY
              MessageService::Admin::Asset.t(MessageService::Admin::Asset::COMPRESSION_COMPLETED, name: @asset.name)
      when MediaConstants::Status::OPTIMAL
              MessageService::Admin::Asset.t(MessageService::Admin::Asset::COMPRESSION_OPTIMAL, name: @asset.name)
      when MediaConstants::Status::FAILED
              MessageService::Admin::Asset.t(MessageService::Admin::Asset::COMPRESSION_FAILED, name: @asset.name)
      else
              MessageService::Admin::Asset.t(MessageService::Admin::Asset::COMPRESSION_IN_PROGRESS, name: @asset.name)
      end

      user_id = @asset.created_by_id.presence || @asset.updated_by_id.presence
      if user_id.present?
        SocketService::Client.broadcast(user_id: user_id, message: msg, data: payload)
      end
    rescue => e
      Rails.logger.error("[CompressAudioJob] Broadcast error for asset #{@asset.id}: #{e.message}")
    end

    def download_from_storage
      require "tempfile"

      ext = @asset.extension.present? ? ".#{@asset.extension}" : ".m4a"
      @temp_dir = Dir.mktmpdir("media_compress")
      input_path = File.join(@temp_dir, "input#{ext}")

      StorageService::Client.download(@asset.storage_key, input_path)

      Rails.logger.info("[CompressAudioJob] Downloaded #{File.size(input_path)} bytes to #{input_path}")
      input_path
    end

    def reupload_compressed(compressed_path)
      result = StorageService::Client.upload(
        compressed_path,
        storage_key: @asset.storage_key,
        folder: File.dirname(@asset.storage_key.to_s).presence || "admin_uploads/audio",
        resource_type: AssetConstants::AssetFormat.storage_resource_type(@asset.extension),
        overwrite: true
      )

      @upload_result = result
    end

    def finalize_asset(compressed_path)
      attrs = {
        url: @upload_result[:url],
        size_bytes: @upload_result[:bytes] || File.size(compressed_path),
        status: MediaConstants::Status::READY
      }

      out_ext = File.extname(compressed_path).delete(".").downcase.presence
      if out_ext.present? && out_ext != @asset.extension
        attrs[:extension] = out_ext
        attrs[:format] = AssetConstants::AssetFormat.from_extension(out_ext) || @asset.format
      end

      @asset.update!(attrs)
    end

    def cleanup_temp_files
      FileUtils.rm_rf(@temp_dir) if @temp_dir && Dir.exist?(@temp_dir)
    end
  end
end
