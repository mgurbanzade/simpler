require_relative 'view'

module Simpler
  class Controller

    attr_reader :name, :request, :response

    def initialize(env)
      @name = extract_name
      @request = Rack::Request.new(env)
      @response = Rack::Response.new
    end

    def make_response(action)
      @request.env['simpler.controller'] = self
      @request.env['simpler.action'] = action

      set_default_headers
      send(action)
      write_response

      @response.finish
    end

    private

    def status(code)
      @response.status = code
    end

    def headers
      @response.headers
    end

    def extract_name
      self.class.name.match('(?<name>.+)Controller')[:name].downcase
    end

    def set_default_headers
      @response['Content-Type'] = 'text/html'
    end

    def body_response
      body = render_body
      @response.write(body)
    end

    def write_response
      body_response if @response.body.empty?
    end

    def render_body
      View.new(@request.env).render(binding)
    end

    def params
      @request.params
    end

    def plain(text)
      @response.write(text)
      @response['Content-Type'] = 'text/plain'
    end

    def inline(text)
      @response.write(ERB.new(text).result(binding))
    end

    def render(template)
      case template
      when template[:plain]
        plain(template[:plain])
      when template[:inline]
        inline(template[:inline])
      else
        @request['simpler.template'] = template
      end
    end

  end
end
