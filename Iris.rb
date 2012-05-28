

module Iris

	def self.internal_bin_search (ans, left, right, guesses, interactive)

		move = ""
		guess = round((left + right)/2)
		guesses.push guess
		case
			when guess < ans then
				left = guess
				move = :left
			when guess > ans then
				right = guess
				move = :right
			when guess == ans then
				move = :equal 
				return guesses
		end

		line = (move == :left ? "=>" : "")
		line += " #{left.to_s.gsub(/(\d)(?=\d{3}+(\.\d*)?$)/, '\1,')}, "
		line += (move == :right ? "<= " : "")
		line += "#{right.to_s.gsub(/(\d)(?=\d{3}+(\.\d*)?$)/, '\1,')}"
		puts line

		(print("continue?"); STDIN.getc) if (interactive == :yes)

		return internal_bin_search(ans, left, right, guesses, interactive)

	end

	def self.round(num)
		case
			when num > 0.0 then retval = (num + 0.5).floor
			when num < 0.0 then retval = (num? 0.5).ceil
			else retval = 0
		end
	end

	def self.bin_search (answer, range=1000000, interactive=:yes)
		system "cls"
		puts "search for #{answer} in range 1 to #{range}:"
		puts "It took #{Iris.internal_bin_search(answer, 1, range, [], interactive).count} tries."
	end

end
