class MirrorZ
  attr_reader :sites

  GITHUB_SITES_URI = 'https://raw.githubusercontent.com/tuna/mirrorz/master/src/config/mirrors.js'.freeze

  def initialize
    sync_sites
  end

  def sync_sites
    $logger.info('Syncing sites')
    @full_sites = latest_full_sites
    @sites = @full_sites.map { |site| site[:site] }
    $logger.info('Synced sites')
  end

  private

  def mirrorz_json_uris
    response = Faraday.get(GITHUB_SITES_URI)
    YAML.safe_load(response.body[response.body.index('[')..])
  end

  def latest_full_sites
    uris = mirrorz_json_uris
    uris.map do |uri|
      response = Faraday.get(uri)
      JSON.parse(response.body, symbolize_names: true)
    rescue StandardError
      nil
    end.compact
  end
end
