require 'bibtex'

module Jekyll
  class FilteredBibliographyGenerator < Generator
    safe true
    priority :high

    def generate(site)
      # Store bibliography data for use in templates
      bib_file = File.join(site.source, site.config['scholar']['source'], site.config['scholar']['bibliography'])
      
      begin
        bib = BibTeX.open(bib_file)
        
        site.config['scholar_entries'] ||= {}
        
        first_author = []
        key_author = []
        
        # bib.entries returns an array of [key, entry] pairs
        bib.entries.each do |entry_pair|
          key, entry = entry_pair
          contribution = entry.contribution.to_s.strip if entry.respond_to?(:contribution)
          contribution ||= ''
          
          if contribution == 'firstauthor'
            first_author << entry
          elsif contribution == 'keyauthor'
            key_author << entry
          end
        end
        
        site.config['scholar_entries']['firstauthor'] = first_author
        site.config['scholar_entries']['keyauthor'] = key_author
        
        Jekyll.logger.info("FilteredBibliography:", "Loaded #{first_author.length} first-author and #{key_author.length} co-author entries")
      rescue => e
        Jekyll.logger.error("FilteredBibliographyGenerator:", "Error: #{e.message}")
        site.config['scholar_entries'] = { 'firstauthor' => [], 'keyauthor' => [] }
      end
    end
  end

  class FilteredBibliographyTag < Liquid::Tag
    def initialize(tag_name, args, tokens)
      super
      @contribution_type = args.strip
    end

    def render(context)
      site = context.registers[:site]
      entries = site.config.dig('scholar_entries', @contribution_type) || []
      
      return '<p>No entries found.</p>' if entries.empty?
      
      output = '<ol class="bibliography" reversed="reversed">'
      entries.reverse.each do |entry|
        output += render_entry(entry)
      end
      output += '</ol>'
      
      output
    end

    def render_entry(entry)
      # Format entry based on type
      title = entry.title.to_s.gsub(/[{}]/, '').gsub(/\\[a-zA-Z]+\{?\}?/, '') if entry.respond_to?(:title)
      
      # Format authors using CiteProc data for cleaner output
      authors = if entry.respond_to?(:author)
                  citeproc_data = entry.to_citeproc
                  author_list = citeproc_data['author'] || []
                  author_array = author_list.map do |author|
                    given = (author['given'] || '').to_s
                    family = (author['family'] || '').to_s
                    
                    # Clean up LaTeX in both given and family names
                    # Remove braces: {text} -> text
                    given = given.gsub(/\{/, '').gsub(/\}/, '')
                    family = family.gsub(/\{/, '').gsub(/\}/, '')
                    # Remove LaTeX commands: \L -> L, \^i -> i, etc
                    given = given.gsub(/\\([a-zA-Z]+)/, '\1').gsub(/\\(.?)/, '')
                    family = family.gsub(/\\([a-zA-Z]+)/, '\1').gsub(/\\(.?)/, '')
                    
                    # Clean whitespace
                    given = given.gsub(/\s+/, ' ').strip
                    family = family.gsub(/\s+/, ' ').strip
                    
                    # Format as "Given Family" for author lists, skip empty names
                    if given.empty?
                      family
                    elsif family.empty?
                      given
                    else
                      "#{given} #{family}"
                    end
                  end
                  author_array.reject(&:empty?).join(', ')
                else
                  ''
                end
      
      year = entry.year.to_s if entry.respond_to?(:year)
      journal = (entry.journal.to_s if entry.respond_to?(:journal)) || ''
      doi = entry.doi.to_s if entry.respond_to?(:doi)
      
      doi_link = (doi && !doi.empty?) ? "<a href=\"http://doi.org/#{doi}\" target=\"_blank\" class=\"btn-pill btn-doi\">DOI</a>" : ''
      
      <<-HTML
<li><div class="pub-entry">
  <div class="text-justify">
    #{format_authors_with_bold(authors)} (#{year}). <em>#{title}</em>. #{journal}
  </div>
  #{doi_link}
</div></li>
      HTML
    end

    def format_authors_with_bold(authors_string)
      # Split authors and make only the first one bold
      authors = authors_string.split(', ')
      if authors.length > 0
        "<strong>#{authors[0]}</strong>" + (authors.length > 1 ? ", #{authors[1..-1].join(', ')}" : "")
      else
        authors_string
      end
    end
  end
end

Liquid::Template.register_tag('filtered_bibliography', Jekyll::FilteredBibliographyTag)



