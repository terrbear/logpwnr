require 'net/ssh'
require 'net/scp'
class Harvester < Application
  def index
    @apps = App.find(:all)
    render
  end
  
  def harvest
    @app = App.find(params[:id])
    @output = ""
    @app.harvest!
    render
  end
end
