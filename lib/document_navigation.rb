# Internal contents links use the same caret and speech behavior in the
# rulebooks and the Markdown README. External links stay with the host.
module GameRoomDocumentNavigation
  def readupdate
    if key_pressed?(:key_enter) && (heading = @contents_targets[active_link])
      @index = @check = heading.from
      espeech(text_range(heading.from, heading.to))
      return
    end
    super
  end

  private

  def active_link
    links = @elements.select { |element| [EditBox::Element::Link, EditBox::Element::Frame].include?(element.type) }
    links.reverse.find { |element| element.from <= @index && element.to >= @index } ||
      links.reverse.find { |element| element.from >= line_beginning && element.to <= line_ending }
  end
end
