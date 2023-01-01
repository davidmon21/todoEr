require "json"
require "time"
# todo time based on default sleep time
module ToDo
    class ListHandle
        attr_accessor :items, :file_location
        def initialize(file_location)
            unless File.exists? file_location
                self.items = {}
                File.write(file_location, JSON.dump(items))
            end
            self.file_location = file_location
            self.items = JSON.parse(File.read(file_location))
            self.update_items
        end
        def update_items
            remove_items = []
            self.items.each do |item,states|
                if states["type"] == "Daily"  
                    if states["due"] < Time.now.to_i && states["completed"]
                        states["due"]+=24*60*60
                        states["completed"] = false
                    elsif states["due"] < Time.now.to_i && !states["completed"]
                        states["fail_count"]+=1 
                        states["due"]+=24*60*60
                    end
                elsif states["type"] == "Due Date" 
                    if states["due"] < Time.now.to_i
                        if states["completed"]
                            remove_items.append item
                        else
                            states["fail_count"]+=1 
                            states["due"]=Time.now.to_i+60*60*24
                        end
                    elsif states["completed"]
                        remove_items.append item
                    end
                else
                    remove_items.append item if states["completed"]
                end
            end
            for item in remove_items
                self.items.delete item
            end
            self.commit_update
        end
        def add_todo(todo,time=0,type="Daily",due_date=nil)
            unless self.items.has_key? todo 
                self.items[todo] = {}
                case type
                when "Daily"
                    date = Time.now
                    self.items[todo]["type"] = type
                    self.items[todo]["due"] = Time.new(date.year,date.month,date.day+1,time).to_i
                    self.items[todo]["completed"] = false 
                    self.items[todo]["fail_count"] = 0
                when "Due Date" 
                    parts = due_date.split("/").map {|i| i.to_i}
                    self.items[todo]["type"] = type
                    self.items[todo]["due"] = Time.new(parts[0],parts[1],parts[2],time).to_i
                    self.items[todo]["completed"] = false
                    self.items[todo]["fail_count"] = 0
                else 
                    self.items[todo]["type"] = "Undefined"
                    self.items[todo]["completed"] = false 
                end
                self.commit_update
            end
            self.update_items
        end
        def mark_complete(todo)
            if self.items.has_key? todo 
                self.items[todo]["completed"] = true 
                self.commit_update
            end
            self.update_items
        end
        def mark_late_complete(todo)
            if self.items.has_key? todo
                if self.items[todo]["fail_count"] > 0 && self.items[todo]["due"] > Time.now.to_i
                    self.items[todo]["fail_count"]-=1
                end
            end
            
        end
        def print_list
            self.update_items
            self.items.each do | item, states |
                puts item
                puts "\t#{states["type"]}"
                puts "\t#{Time.at(states["due"])}"
                puts "\tFailed to Complete #{states["fail_count"]} times" if states["fail_count"] > 0 
                if states["completed"]
                    puts "\tCompleted ✔\n" 
                else
                    puts "\tUncomplete"
                end
            end
        end
        def commit_update
            File.write(self.file_location, JSON.dump(self.items))
            self.items = JSON.parse(File.read(file_location))
        end
    end
end