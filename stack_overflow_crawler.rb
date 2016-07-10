require 'nokogiri'
require 'open-uri'

class StackOverflowCrawler

  attr_reader :tag, :max_pages_to_visit, :max_pages_to_visit

  def initialize(tag, max_pages_to_visit)
    @tag = tag
    @max_pages_to_visit = max_pages_to_visit
  end

  # Find in batches of 15 and process. Avoid having all
  # the result set in memory.
  def run
    # Hardcoding this here, we can later decide to parametrize it
    results_per_page = 15
    users = []
    execute_in_batches(max_pages_to_visit, results_per_page) do |page, remaining|
      question_pages = most_voted_questions(tag, page, results_per_page, remaining)
      accepted_answer_users = question_pages.map {|page| get_answering_user(page)}
      users.concat(accepted_answer_users.compact)
    end
    histogram = users_histogram(users).sort_by {|a, b| -b }
    histogram.each do |user, answers|
      puts "#{user} - #{answers}"
    end
  end

  private

  # Calculate the pagination for a number of required
  # results and a batch size. Execute the method block
  # the required amount of times, passing as a parameter
  # the remaining elements.
  def execute_in_batches(count, batch_size)
    block_executions = count / batch_size
    block_executions += 1 if count % batch_size > 0
    remaining = count
    block_executions.times do |i|
      if block_given?
        yield(i+1, remaining)
      end
      remaining -= batch_size
    end
  end

  # Answers a hash with the form user => number of questions answered.
  def users_histogram(users)
    users.inject(Hash.new(0)) do |total, user|
      total[user] += 1;
      total
    end
  end

  # Fetch a url and return a nokogiri node.
  def fetch(url)
    # Wait a bit, in case SO bans if too many requests come together in
    # a short amount of time.
    rand(0.7..1.5)
    print "Fetching #{url}"
    page = Nokogiri::HTML(open(url))
    puts " [done]"
    page
  end

  # Get the pages for the most voted questions in a given tag
  # Since we are fetching pages in batches we also take
  # the page index and the page size. Finally, to avoid
  # making unneeded requests in the last page, we also need
  # to know how many items are required.
  def most_voted_questions(tag, page, page_size, required)
    list_page = fetch(list_url(tag, page, page_size))
    links_to_fetch = list_page.css('a.question-hyperlink').take(required)
    links_to_fetch.map do |a|
      fetch(question_url(a['href']));
    end
  end

  # Returns the user name of the accepted answer or nil if none.
  # Some cases to consider:
  # - There may be no accepted answer
  # - There may be more than a user in an answer container (e.g. a user correcting the answer).
  # - The accepted answer may be from the community wiki
  # If there is an actual user we have to look for the parent <td> of a <div class="user-action-time">
  # that has `answered` as part if its content.
  def get_answering_user(answer_page)
    accepted_answer_div = answer_page.css('div.accepted-answer')
    # No accepted answer
    return nil if accepted_answer_div.empty?
    cell_xpath = './/td[@class="post-signature" and .//*/div[@class="user-action-time" and contains(text(), "answered")]]'
    containing_cell = accepted_answer_div.xpath(cell_xpath)
    user_anchor = containing_cell.css('div.user-details a').first
    user_anchor ? user_anchor.text : nil
  end

  def base_url
    'http://stackoverflow.com'
  end

  def list_url(tag, page, page_size)
    "#{base_url}/questions/tagged/#{tag}?sort=votes&page=#{page}&pageSize=#{page_size}"
  end

  def question_url(href)
    "#{base_url}/#{href}"
  end

end
