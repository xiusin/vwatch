module main

import os
import time
import term
import sync
import toml
import toml.to
import json

struct WatchFile {
	file_path string
mut:
	mtime i64
}

struct WatchCfg {
pub mut:
	max_file_cnt       i64
	watch_extensions   []string
	build_on_change    []string
	ignores_pattern    string
	build_bin_name     string
	watch_dir          string
	git_pull           bool
	print_startup_info bool
}

fn (mut cfg WatchCfg) check() {
	if cfg.build_on_change.len == 0 {
		cfg.build_on_change = ['go', 'build', '-o']
		cfg.build_on_change[0] = os.find_abs_path_of_executable(cfg.build_on_change[0]) or {
			panic(err)
		}
	}
	if cfg.watch_extensions.len == 0 {
		cfg.watch_extensions = ['.go', '.v', '.toml', '.yaml']
	}
	if cfg.watch_dir.len == 0 {
		cfg.watch_dir = os.abs_path('.')
	}

	if cfg.max_file_cnt == 0 {
		cfg.max_file_cnt = 300
	}
	if cfg.build_bin_name.len == 0 {
		cfg.build_bin_name = os.base(os.abs_path('.'))
	}
	$if windows {
		cfg.build_bin_name += '.exe'
	}
}

struct Watch {
	sync.Mutex
pub mut:
	started         bool
	building        bool
	process_running bool
	signal          chan os.Signal
	build_bin_name  string
	exited          bool
	log_prefix      string      = term.bg_green('[INFO]')
	warning_prefix  string      = term.bg_red('[ERRO]')
	process         &os.Process = unsafe { nil }
	files           map[string]&WatchFile
	root_path       string
	event           chan string
	cfg             WatchCfg
	max_count       u64
	sw              time.StopWatch = time.new_stopwatch()
}

fn (mut w Watch) register_exit_signal() {
	println(w.log_prefix + '💻 Start watching... ')
	os.signal_opt(os.Signal.int, fn [mut w] (_ os.Signal) {
		w.exited = true
		if w.process_running {
			w.signal <- os.Signal.kill
		}
		time.sleep(time.millisecond * 100)
		println(w.log_prefix + '👋🏻 ByeBye...')
		exit(0)
	}) or { panic('${err}') }
}

fn (mut w Watch) git_pull() {
	for {
		result := os.execute('git pull --no-edit')
		if result.exit_code != 0 {
			println(w.warning_prefix + ' ' + result.output)
		}
		time.sleep(time.second * 10)
	}
}

fn (mut w Watch) listen_event() {
	spawn fn [mut w] () {
		for {
			time.sleep(time.second * 3)
			w.@lock()
			w.scan_and_register_file(w.root_path)
			w.unlock()
		}
	}()

	for {
		w.@lock()
		mut send_event_time := i64(0)
		for _, mut file in w.files {
			if !os.is_file(file.file_path) {
				println(w.log_prefix + ' file ${file.file_path} ${term.red('deleted')}.')
				w.files.delete(file.file_path)
			} else {
				mtime := os.file_last_mod_unix(file.file_path)
				if mtime > file.mtime {
					println(w.log_prefix + ' file ${file.file_path} ${term.yellow('modified')}.')
					file.mtime = mtime
				} else {
					continue
				}
			}

			if w.started && time.now().unix - send_event_time > 3 && !w.building {
				w.event <- file.file_path
				send_event_time = time.now().unix
				break
			}
			time.sleep(time.microsecond * 30)
		}
		w.unlock()
		time.sleep(time.second)
	}
}

fn (mut w Watch) scan_and_register_file(file_path string) {
	files := os.ls(file_path) or { panic(err) }
	for _, file in files {
		if w.max_count == 0 {
			return
		}
		if file.starts_with('.') {
			continue
		}
		full_path := os.join_path(file_path, file)
		if os.is_dir(full_path) {
			w.scan_and_register_file(full_path)
		} else if w.cfg.watch_extensions.contains(os.file_ext(file)) && full_path !in w.files {
			w.max_count--
			if w.cfg.print_startup_info {
				println(w.log_prefix + ' Register ${full_path}')
			}
			w.files[full_path] = &WatchFile{
				file_path: full_path
				mtime: os.file_last_mod_unix(full_path)
			}
		}
	}
}

fn (mut w Watch) build_run() {
	w.building = true
	println(w.log_prefix + ' Content is updated and rebuilt...')
	w.sw.restart()
	result := os.execute(w.cfg.build_on_change.join(' ') + ' ' + w.build_bin_name)
	w.sw.stop()
	println(w.log_prefix + ' build use time: ${w.sw.elapsed()}')
	if result.exit_code == 0 {
		if w.process_running {
			w.signal <- os.Signal.kill
		}
		time.sleep(time.second)
		mut process := os.new_process('./' + w.build_bin_name)
		spawn fn [mut w, mut process] () {
			select {
				_ := <-w.signal {
					process.signal_kill()
					unsafe { process.free() }
					println(w.log_prefix + ' exit sub process ${process.status}.')
					w.process_running = false
				}
			}
		}()
		w.process_running = true
		spawn fn [mut process, mut w] () {
			process.wait()
			unsafe { process.free() }
			w.process_running = false
		}()
	} else {
		println(w.warning_prefix + ' Build error reason: ${result.output}')
	}
	w.building = false
}

fn main() {
	toml_doc := to.json(toml.parse_file('vwatch.toml') or { toml.Doc{} })
	mut cfg := json.decode(WatchCfg, toml_doc) or { panic(err) }
	println(cfg)
	cfg.check()
	mut watcher := &Watch{
		signal: chan os.Signal{}
		root_path: cfg.watch_dir
		build_bin_name: cfg.build_bin_name
		event: chan string{}
		cfg: cfg
	}

	watcher.register_exit_signal()
	watcher.scan_and_register_file(watcher.root_path)
	spawn watcher.listen_event()
	if cfg.git_pull {
		spawn watcher.git_pull()
	}
	for {
		if watcher.exited {
			exit(0)
		}
		if !watcher.started {
			watcher.started = true
			watcher.build_run()
		} else {
			_ = <-watcher.event
			watcher.build_run()
		}
	}
}
