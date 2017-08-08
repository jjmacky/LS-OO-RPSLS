class WeightedArray < Array
  def weighted_sample(weights)
    weighted_array = []
    total = weights.reduce(:+)
    each_with_index do |e, i|
      sample_size = (weights[i] / total) * 100
      weighted_array += Array.new(sample_size).fill(e)
    end
    weighted_array.sample
  end
end

VALUES = WeightedArray.new(['rock', 'lizard', 'spock', 'scissors', 'paper'])

class Move
  attr_accessor :value

  def initialize(value)
    self.value = value
  end

  def self.winning(move1, move2)
    idxs = [VALUES.index(move1.value), VALUES.index(move2.value)]
    idxs.all?(&:even?) ? VALUES[idxs.max] : VALUES[idxs.min]
  end

  def to_s
    value
  end
end

class Player
  attr_accessor :move, :name, :points

  def initialize
    set_name
    self.points = 0
  end

  def add_point
    self.points += 1
  end

  def reset_points
    self.points = 0
  end
end

class Human < Player
  def set_name
    n = ''
    loop do
      puts "what's your name?"
      n = gets.chomp
      break unless n.empty?
      puts "Sorry, must enter a value."
    end
    self.name = n
  end

  def choose
    choice = nil
    loop do
      puts ""
      puts "Plese enter choice from #{VALUES.join(', ')}."
      choice = gets.chomp
      break if VALUES.include? choice
      puts "Sorry, invalid choice."
    end
    self.move = Move.new(choice)
  end
end

class Computer < Player
  attr_accessor :computer_weights

  def set_name
    name
  end

  def choose
    move = VALUES.weighted_sample(computer_weights)
    self.move = Move.new(move)
  end
end

class SmartComputer < Computer
  attr_accessor :opponent_weights, :opponent_move, :prior, :posterior
  INITIAL_OPPONENT_WEIGHTS = [0.2, 0.2, 0.2, 0.2, 0.2]
  TUNING_PARAM = 2

  def initialize
    self.prior = INITIAL_OPPONENT_WEIGHTS
    self.posterior = prior
    self.name = "Smarty Pants"
    self.opponent_move = VALUES.weighted_sample(prior)
    super
  end

  def choose
    calculate_opponent_move
    idx = VALUES.index(opponent_move)
    self.move = Move.new(VALUES[(idx + 2) % VALUES.size])
  end

  def calculate_opponent_move
    self.opponent_move = VALUES.weighted_sample(posterior)
  end

  def update_opponent_weights(opponent_move)
    data = [1, 1, 1, 1, 1]
    data[VALUES.index(opponent_move.to_s)] = TUNING_PARAM
    numerator = prior.each_index.map { |i| prior[i] * data[i] }
    denominator = numerator.reduce(:+)
    self.posterior = numerator.map { |n| (n / denominator).round(2) }
    self.prior = WeightedArray.new(posterior)
  end
end

class R2D2 < Computer
  def initialize
    self.computer_weights = [0.2, 0.2, 0.2, 0.2, 0.2]
    self.name = 'R2D2'
    super
  end
end

class Hal < Computer
  def initialize
    self.computer_weights = [0.8, 0.05, 0.05, 0.05, 0.05]
    self.name = 'Hal'
    super
  end
end

class Chappie < Computer
  def initialize
    self.computer_weights = [0.01, 0.01, 0.32, 0.32, 0.32]
    self.name = 'Chappie'
    super
  end
end

class Spock < Computer
  def initialize
    self.computer_weights = [0.0, 0.0, 1.0, 0.0, 0.0]
    self.name = 'Spock'
    super
  end
end

class Number5 < Computer
  def initialize
    self.computer_weights = [0.25, 0.25, 0.25, 0.25, 0.0]
    self.name = 'Number 5'
    super
  end
end

class RPSGame
  COMPUTER_PLAYERS = [R2D2.new, Hal.new, Chappie.new, Spock.new, Number5.new]
  WINNING_SCORE = 5
  attr_accessor :human, :computer, :winner

  def initialize
    self.human = Human.new
    @game_title = VALUES.map(&:capitalize).join(', ')
  end

  def display_welcome_message
    puts "Welcome to #{@game_title}!"
    puts "The first player to #{WINNING_SCORE} wins!"
  end

  def display_goodbye_message
    puts "Thanks for playing #{@game_title}. Good bye!"
  end

  def choose_computer_opponent
    str = "Would you like to play against a smart computer (type 'smart')"\
          " or a silly computer (type 'silly')"
    choice = nil
    loop do
      puts str
      choice = gets.chomp
      break if ['smart', 'silly'].include? choice
      puts "Sorry, invalid choice."
    end
    self.computer = if choice == 'smart'
                      SmartComputer.new
                    else
                      COMPUTER_PLAYERS.sample
                    end
  end

  def get_winner(human, computer)
    if human.move.to_s == computer.move.to_s
      self.winner = nil
    else
      winning_move = Move.winning(human.move, computer.move)
      self.winner = human.move.to_s == winning_move ? human : computer
    end
  end

  def display_moves
    puts "#{human.name} chose #{human.move}."
    puts "#{computer.name} chose #{computer.move}."
  end

  def display_winner
    get_winner(human, computer)
    puts winner.nil? ? "It's a tie!" : "#{winner.name} won that round!"
  end

  def display_score
    puts "#{human.name} has #{human.points} points."
    puts "#{computer.name} has #{computer.points} points."
  end

  def display_winner_message
    puts "#{winner.name} won the match!"
  end

  def match_winner?
    winner.points >= WINNING_SCORE
  end

  def play_again?
    answer = nil
    loop do
      puts "Would you like to play again? (y/n)?"
      answer = gets.chomp
      break if ['y', 'n'].include?(answer.downcase)
      puts "Sorry, must be y or n."
    end

    return true if answer == 'y'
    false
  end

  def reset_points
    human.reset_points
    computer.reset_points
  end

  def play_round
    human.choose
    computer.choose
    if computer.is_a? SmartComputer
      computer.update_opponent_weights(human.move)
    end
    display_moves
    display_winner
  end

  def play_match
    loop do
      display_welcome_message
      choose_computer_opponent
      loop do
        play_round
        next display_score if winner.nil?
        winner.add_point
        display_score
        break if match_winner?
      end
      display_winner_message
      break unless play_again?
      reset_points
    end
    display_goodbye_message
  end
end

RPSGame.new.play_match
