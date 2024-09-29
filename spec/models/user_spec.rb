require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    # email
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }

    context 'when email is not the email format' do
      let(:user) { build(:user, email: 'user') }
      it 'email should be the correct email format' do
        expect(user).not_to be_valid
      end
    end

    # password
    it { should validate_presence_of(:password) }
    it { should validate_length_of(:password).is_at_least(6) }

    # name
    it { should validate_length_of(:name).is_at_most(50) }

    context 'when name is blank' do
      let(:user) { build(:user, name: '') }
      it 'should allow the blank' do
        expect(user).to be_valid
      end
    end

    context 'when name includes special characters' do
      let(:user) { build(:user, name: '<:;?') }

      it 'should not allow the special characters in name' do
        expect(user).not_to be_valid
      end
    end

    # photo
    context 'when photo is not valid url' do
      let(:user) { build(:user, photo: 'testing.com') }
      it 'photo should not be invalid url' do
        expect(user).not_to be_valid
      end
    end

    context 'when photo is a valid url' do
      let(:user) { build(:user, photo: 'https://www.google.com/') }
      it 'photo should be valid url' do
        expect(user).to be_valid
      end
    end
  end
end
