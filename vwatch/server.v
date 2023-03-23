module vwatch

import vweb
import os

struct App {
	vweb.Context
}

pub fn server(port int) ! {
	mut app := &App{}
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
