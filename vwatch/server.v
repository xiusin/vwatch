module vwatch

import vweb
import os
import net.http
import net.urllib

// Allows local static file hosting, starts listening service on the specified port,
// allows direct proxy interface requests, needs to set proxy domain name
// eg: vwatch --port=8089 --domain=http://www.example.org

// App a vweb service
struct App {
	vweb.Context
pub mut:
	port   int    [vweb_global]
	domain string [vweb_global]
}

['/api/:url...'; get; head; post; put]
pub fn (mut app App) proxy_api(url_path string) vweb.Result {
	domain := if app.domain.len > 0 {
		app.domain
	} else {
		host := app.req.header.get(http.CommonHeader.host) or { 'localhost:${app.port}' }
		'http://${host}'
	}

	mut url := urllib.parse(domain) or { return app.server_error(500) }

	full_path := domain + '/api/' + url_path
	method := http.method_from_str(app.req.method.str())
	mut req := http.new_request(method, full_path, app.req.data)
	mut headers := app.req.header
	headers.delete(http.CommonHeader.accept_encoding)
	headers.delete(http.CommonHeader.content_length)
	headers.set(http.CommonHeader.host, url.host + ':' + url.port())
	req.header = headers
	req.cookies = app.req.cookies.clone()
	req.allow_redirect = true
	req.validate = false
	mut resp := req.do() or {
		app.server_error(500)
		return app.text(err.str())
	}
	app.set_status(resp.status_code, resp.status_msg)
	mut content_type := resp.header.get(.content_type) or { 'text/plain' }
	app.set_content_type(content_type)
	return app.ok(resp.body)
}

pub fn server(port int, domain string) ! {
	mut app := &App{
		port: port
		domain: domain
	}

	static_dir := os.getwd()
	os.chdir(static_dir)!
	app.handle_static(static_dir, true)
	register_default_index(mut app, static_dir, '/')

	vweb.run(app, port)
}

fn register_default_index(mut app App, dir string, mon string) {
	mont := '${mon.trim_right('/')}/'
	app.serve_static(mont, os.join_path(dir, 'index.html'))
	files := os.ls(dir) or { panic(err) }
	for file in files {
		full_path := os.join_path(dir, file)
		if os.is_dir(full_path) {
			register_default_index(mut app, full_path, mont + file)
		}
	}
}
