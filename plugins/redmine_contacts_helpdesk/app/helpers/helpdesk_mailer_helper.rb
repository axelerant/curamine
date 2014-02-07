# encoding: utf-8
# include RedCloth

module HelpdeskMailerHelper
  def textile(text)
    PatchedRedCloth.new(text).to_html
  end
end

class PatchedRedCloth < RedCloth3
  def initialize(*args)
    super
    self.hard_breaks=true
  end
  
  private
  
  # Patch for RedCloth.  Fixed in RedCloth r128 but _why hasn't released it yet.
  # <a href="http://code.whytheluckystiff.net/redcloth/changeset/128">http://code.whytheluckystiff.net/redcloth/changeset/128</a>
  def hard_break( text ) 
    text.gsub!( /(.)\n(?!\n|\Z| *([#*=]+(\s|$)|[{|]))/, "\\1<br />" ) if hard_breaks
  end

end

