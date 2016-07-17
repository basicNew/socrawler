# S.O. Crawler
A toy web crawler written just for fun. The idea is to see the users and number of accepted answers they got between the most voted questions for a given tag.

## Getting Started

1. Clone this repository:

        $ git clone git@github.com:basicNew/socrawler.git

2. cd in the repo. This will create the appropriate gemset if you have rvm installed.

        $ cd socrawler

3. Install bundler if you haven't already

        $ gem install bundler

4. Install the required gems

        $ bundle install

5. Open up an irb session

        $ irb -r ./reload.rb

6. Play with it

        2.2.3 :001 > StackOverflowCrawler.new('ruby', 100).run()

Note: you can change any code and just type `reload!` for irb to pick the changes.


## License

[MIT](http://www.opensource.org/licenses/MIT)
