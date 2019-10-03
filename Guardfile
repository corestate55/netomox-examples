top_files = Pathname.glob('./model_defs/*.rb')

top_files.each do |top_file|
  bn = File.basename(top_file, '.rb')
  # puts "# def group: #{bn}"
  group bn.intern do
    guard :shell do
      required_files = File.readlines(top_file)
                         .grep(/require_relative/)
                         .map do |m|
        m =~ /require_relative (.*)$/
        "./model_defs/#{$1.gsub!(/['"]/,'')}.rb"
      end
      required_files.push(top_file)
      # puts "Watch files = #{required_files}"
      required_files.each do |f|
        watch f do
          `bundle exec rake TARGET=#{top_file}`
        end
      end
    end
  end
end


