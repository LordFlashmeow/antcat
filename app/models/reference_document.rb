# TODO: See https://github.com/calacademy-research/antcat/issues/878
# TODO: Paperclip has been deprecated, see https://github.com/thoughtbot/paperclip

class ReferenceDocument < ApplicationRecord
  belongs_to :reference

  validate :check_url, :ensure_url_has_protocol

  has_attached_file :file,
    url: ':s3_domain_url',
    path: ':id/:filename',
    bucket: 'antcat',
    storage: :s3,
    s3_credentials: Rails.root + 'config/s3.yml',
    s3_permissions: 'authenticated-read',
    s3_region: 'us-east-1',
    s3_protocol: 'http'
  before_post_process :transliterate_file_name
  do_not_validate_attachment_file_type :pdf
  has_paper_trail

  def pdf
    true
  end

  def url_via_file_file_name
    "http://antcat.org/documents/#{id}/#{file_file_name}"
  end

  def downloadable?
    return true if hosted_by_us?
    url.present? && !hosted_by_antbase? && !hosted_by_hol?
  end

  def actual_url
    hosted_by_us? ? s3_url : url
  end

  # TODO: Rename `reference_documents.url` --> `reference_documents.external_url`.
  def routed_url
    hosted_by_us? ? url_via_file_file_name : url
  end

  private

    def transliterate_file_name
      extension = File.extname(file_file_name).gsub(/^\.+/, '')
      filename = file_file_name.gsub(/\.#{extension}$/, '')
      file.instance_write(:file_name, "#{ActiveSupport::Inflector.parameterize(filename)}.#{ActiveSupport::Inflector.parameterize(extension)}")
    end

    def hosted_by_hol?
      url.present? && url =~ %r{^https?://128.146.250.117}
    end

    def hosted_by_antbase?
      url.present? && url =~ %r{^https?://antbase\.org}
    end

    def check_url
      return if Rails.env.development? # HACK
      return if file_file_name.present? || url.blank?
      # This is to avoid authentication problems when a URL to one of "our" files is copied
      # to another reference (e.g., nested).
      return if /antcat/.match?(url)
      return if hosted_by_hol? || hosted_by_antbase?

      URI.parse(url.gsub(' ', '%20'))
    rescue URI::InvalidURIError
      errors.add :url, 'is not in a valid format'
    end

    def hosted_by_us?
      file_file_name.present?
    end

    def ensure_url_has_protocol
      return if url.blank?
      return if url.match?(%r{^https?://})
      errors.add :url, 'must start with http:// or https://'
    end

    def s3_url
      file.expiring_url 1.day.seconds.to_i
    end
end
