require_relative "game_content"
require_relative "game_room_localization"
require_relative "document_navigation"

class GameRoomReadmeView < EditBox
  include GameRoomDocumentNavigation

  REPOSITORY_FILES = "https://github.com/papierek1997/elten-game-room/blob/main/".freeze
  FILES = {"pl" => "README.md", "en" => "content/readme/EN.md", "cs" => "content/readme/CS.md",
    "es" => "content/readme/ES.md", "ru" => "content/readme/RU.md"}.freeze

  def self.path(language = GameRoomLocalization.primary_language)
    FILES.fetch(language, FILES.fetch("en"))
  end

  def initialize(header, text:)
    super(GameRoomContent.utf8(header), type: Flags::ReadOnly | Flags::MultiLine | Flags::MarkDown,
      text: GameRoomContent.utf8(text), quiet: true)
    connect_links
  end

  private

  def connect_links
    headings = {}
    @elements.select { |element| element.type == Element::Header }.each do |heading|
      title = text_range(heading.from, heading.to)
      slug = title.downcase.gsub(/[^\p{L}\p{N}_\- ]/u, "").tr(" ", "-")
      anchor = slug
      suffix = 0
      while headings.key?(anchor)
        suffix += 1
        anchor = "#{slug}-#{suffix}"
      end
      headings[anchor] = heading
    end
    @contents_targets = {}
    @elements.select { |element| element.type == Element::Link }.each do |link|
      url = link.param[1]
      if url.start_with?("#")
        @contents_targets[link] = headings[url.delete_prefix("#")]
      elsif !url.match?(%r{\A(?:[a-z][a-z0-9+.-]*:|//)}i)
        # Developer documents remain in the repository, not in the installer.
        link.param[1] = REPOSITORY_FILES + url
      end
    end
  end
end
