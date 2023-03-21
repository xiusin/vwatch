module vwatch

import vweb
import os

struct App {
	vweb.Context
}

pub fn server() ! {
	mut app := &App{}
	static_dir := os.getwd()
	os.chdir(static_dir)!
	app.handle_static(static_dir, true)
	register_default_index(mut app, static_dir, '/')
	vweb.run(app, 8081)
}

fn register_default_index(mut app App, dir string, mon string) {
	// 递归注册目录下索引文件
	files := os.ls(dir) or { panic(err) }
	for file in files {
		full_path := os.join_path(dir, file)
		if os.is_dir(full_path) {
			app.serve_static(mon, os.join_path(full_path, 'index.html'))
			register_default_index(mut app, full_path, mon + '/' + file + '/')
		}
	}
}
