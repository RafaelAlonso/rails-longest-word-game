require 'open-uri'
require 'nokogiri'

class PagesController < ApplicationController
  def game
    @grid = generate_grid
  end

  def score
    @attempt = params[:guess]
    @grid = params[:grid]
    @start_time = Time.parse(params[:start])
    @end_time = Time.now

    @result = run_game(@attempt, @grid, @start_time, @end_time)

    if session.key?(:user_scores)
      session[:user_scores] << @result[:score]
      session[:user_scores].sort!.reverse!
      if session[:user_scores].length > 10
        session[:user_scores].pop
      end
    else
      session[:user_scores] = [@result[:score]]
    end
  end

  private

  def generate_grid
    grid = []
    10.times { grid << ('A'..'Z').to_a.sample }
    return grid
  end

  def run_game(attempt, grid, start_time, end_time)
    data = get_data(@attempt)

    # Compute the time taken by the user
    time = (end_time - start_time).round

    # Creates the hash result
    result = {
      time: time,
      score: get_score(attempt, grid, data, time),
      message: get_message(data, attempt, grid)
    }

    # returns the hash result
    return result
  end

  def get_data(attempt)
    # get the url from the API, giving the attempt   here
    url = "https://wagon-dictionary.herokuapp.com/#{attempt}"
    # read the url and return the JSON.parsed version of it
    attempt_serialized = open(url).read
    return JSON.parse(attempt_serialized)
  end

  def get_score(attempt, grid, data, result_time)
    # returns score calculated if attempt is an english word and is in the grid, 0 otherwise
    return data['found'] && in_the_grid(attempt, grid) ? (attempt.size * 100 / result_time).round : 0
  end

  def get_message(data, attempt, grid)
    # return this if the word is not found in Le Wagon Dictionary API
    return "Your word is not an english word" unless data['found']
    # return this if the word is not in the grid
    return "Your word is not in the grid" unless in_the_grid(attempt, grid)
    # return this otherwise
    return "You got it! Well done"
  end

  def in_the_grid(attempt, grid)
    grid_hash = {}
    attempt_hash = {}

    # creates hash which counts the amount of letters in the grid
    grid.split(//).each do |letter|
      grid_hash.key?(letter) ? grid_hash[letter] += 1 : grid_hash[letter] = 1
    end

    # creates hash which counts the amount of letters in the attempt
    attempt.upcase.scan(/./).each do |letter|
      attempt_hash.key?(letter) ? attempt_hash[letter] += 1 : attempt_hash[letter] = 1
    end

    # checks if the letters used in the attempt are in the grid AND if they're ysed at a possible amount of times
    attempt_hash.each_key { |k| return false unless grid_hash.key?(k) && grid_hash[k] >= attempt_hash[k] }
    return true
  end
end
