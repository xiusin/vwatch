module vwatch

struct WatchFile {
	file_path string
	mut:
	mtime i64
}
