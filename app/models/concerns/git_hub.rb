module GitHub
  class Error < StandardError; end
  class Forbidden < Error; end
  class NotFound < Error; end

  def application_github_client
    client_id = Rails.application.secrets.github_client_id
    client_secret = Rails.application.secrets.github_client_secret
    Octokit::Client.new(client_id: client_id, client_secret: client_secret, auto_paginate: true)
  end

  # Public
  #
  # rubocop:disable Metrics/CyclomaticComplexity
  def with_error_handling
    yield
  rescue Octokit::Error => err
    case err
    when Octokit::Forbidden           then raise_github_forbidden_error
    when Octokit::NotFound            then raise_github_not_found_error
    when Octokit::ServerError         then raise_github_server_error
    when Octokit::Unauthorized        then raise_github_forbidden_error
    when Octokit::UnprocessableEntity then raise_github_error(err)
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  protected

  def no_cache_headers
    { 'Cache-Control' => 'no-cache, no-store' }
  end

  def raise_github_forbidden_error
    raise GitHub::Forbidden, 'You are forbidden from performing this action on github.com'
  end

  def raise_github_server_error
    raise GitHub::Error, 'There seems to be a problem on github.com, please try again.'
  end

  def raise_github_error(err)
    raise GitHub::Error, build_error_message(err.errors.first)
  end

  def raise_github_not_found_error
    raise GitHub::NotFound, 'Resource could not be found on github.com'
  end

  private

  # Internal
  #
  # rubocop:disable AbcSize
  def build_error_message(error)
    return 'An error has occured' unless error.present?

    error_message = []

    error_message << error[:resource]
    error_message << error[:code].tr('_', ' ') if error[:message].nil?
    error_message << error[:field] if error[:message].nil?
    error_message << error[:message] unless error[:message].nil?

    error_message.map(&:to_s).join(' ')
  end
  # rubocop:enable AbcSize
end
