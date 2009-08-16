Factory.define(:post) do |p|
  p.title "Welcome to my blog!"
  p.comments { |c| [c.association(:comment)] }
end

Factory.define(:comment) do |c|
  c.text "Nice post!"
end