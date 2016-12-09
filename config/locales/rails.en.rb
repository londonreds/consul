{
  :en => {
    :date => {
      :formats => {
        :default => lambda { | time, _| "%A #{time.day.ordinalize} %B %Y" }
      }
    },
    :time => {
      :formats => {
        :datetime => lambda { |time, _| "%A #{time.day.ordinalize} %B %Y %l:%M%P" }
      }
    }
  }
}
