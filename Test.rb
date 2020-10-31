
class Student
    def initialize (languageName,languagePrice)
        @lang=languageName
        @price=languagePrice
    end
    
    def show
        return @lang
    end
end    


s1=Student.new('python','1212')
s2=Student.new('ruby','90')
puts s1.show