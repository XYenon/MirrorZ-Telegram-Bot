class MirrorZ
  attr_reader :sites, :items

  GITHUB_SITES_URI = 'https://raw.githubusercontent.com/tuna/mirrorz/master/src/config/mirrors.js'.freeze

  def initialize
    sync_sites
  end

  def sync_sites
    $logger.info('Syncing sites')
    @full_sites = latest_full_sites.freeze
    @sites = @full_sites.map { |site| site[:site] }.freeze
    set_items
    $logger.info('Synced sites')
  end

  private

  def set_items
    items = []
    @full_sites.each do |full_site|
      full_site[:info].each do |new_item|
        old_item = items.find do |item|
          item[:distro] == new_item[:distro] && item[:category] == new_item[:category]
        end
        items << { distro: new_item[:distro], category: new_item[:category], sites: [] } if old_item.nil?
        old_item ||= items.last
        old_item[:sites] << full_site[:site].clone
        old_item[:sites].last[:items] = new_item[:urls].map do |url|
          { name: url[:name], url: "#{full_site[:site][:url]}#{url[:url]}" }
        end.freeze
      end
    end
    @items = items.sort do |a, b|
      "#{a[:category]}#{a[:distro]}" <=> "#{b[:category]}#{b[:distro]}"
    end.freeze
  end

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
