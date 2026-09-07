module Media
  class GenerateVideoThumbnailJob < ApplicationJob
    queue_as :media

    retry_on MediaService::CompressionError, wait: :polynomially_longer, attempts: 3
    retry_on StorageService::Error, wait: :polynomially_longer, attempts: 3
    discard_on ActiveRecord::RecordNotFound

    def perform(asset_id:, replace: false)
      asset = Asset.find(asset_id)
      return unless asset.compressible_video?
      return if asset.thumbnail.present? && !replace

      temp_dir = Dir.mktmpdir("video_thumbnail")
      input_path = File.join(temp_dir, "input.#{asset.extension.presence || 'mp4'}")
      output_path = File.join(temp_dir, "thumbnail.webp")
      StorageService::Client.download(asset.storage_key, input_path)
      MediaService::VideoThumbnailer.generate(input_path, output_path: output_path)
      result = StorageService::Client.upload(
        output_path,
        storage_key: AssetConstants::AssetName.thumbnail_for(asset, version: replace ? job_id : nil),
        resource_type: "image"
      )

      thumbnail = nil
      Asset.transaction do
        asset.thumbnail&.destroy!
        thumbnail = Asset.create!(
        name: result[:storage_key],
        url: result[:url],
        type: AssetConstants::AssetType::THUMBNAIL,
        format: AssetConstants::AssetFormat::IMAGE,
        extension: result[:format].presence || MediaConstants::IMAGE_EXT_WEBP,
        size_bytes: result[:bytes] || File.size(output_path),
        source: AssetConstants::AssetSource::UPLOAD,
        status: MediaConstants::Status::READY,
        storage_key: result[:storage_key],
        assetable: asset.assetable,
        parent_asset: asset,
        created_by_id: asset.created_by_id
        )
      end
      broadcast(asset, thumbnail)
    rescue StandardError
      StorageService::Client.delete(result[:storage_key]) if result&.dig(:storage_key) && !thumbnail&.persisted?
      broadcast_failure(asset) if asset
      raise
    ensure
      FileUtils.rm_rf(temp_dir) if temp_dir && Dir.exist?(temp_dir)
    end

    private

    def broadcast(asset, thumbnail)
      return if asset.created_by_id.blank?

      SocketService::Client.broadcast(
        user_id: asset.created_by_id,
        message: MessageService::Admin::Asset.t(
          MessageService::Admin::Asset::THUMBNAIL_GENERATED,
          name: asset.name
        ),
        data: {
          type: MediaConstants::SocketEvent::ASSET_THUMBNAIL_GENERATED,
          asset_id: asset.id,
          thumbnail: AssetSerializer.new(thumbnail).serializable_hash[:data][:attributes]
        }
      )
    rescue StandardError => e
      Rails.logger.error("[GenerateVideoThumbnailJob] Broadcast error: #{e.message}")
    end

    def broadcast_failure(asset)
      return if asset.created_by_id.blank?

      SocketService::Client.broadcast(
        user_id: asset.created_by_id,
        message: MessageService::Admin::Asset.t(
          MessageService::Admin::Asset::THUMBNAIL_FAILED,
          name: asset.name
        ),
        data: {
          type: MediaConstants::SocketEvent::ASSET_THUMBNAIL_FAILED,
          asset_id: asset.id
        }
      )
    rescue StandardError => e
      Rails.logger.error("[GenerateVideoThumbnailJob] Failure broadcast error: #{e.message}")
    end
  end
end
