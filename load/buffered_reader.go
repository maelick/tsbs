package load

import (
	"bufio"
	"compress/gzip"
	"io"
	"os"
	"strings"
)

const (
	defaultReadSize = 4 << 20 // 4 MB
)

// GetBufferedReader returns the buffered Reader that should be used by the file loader
// if no file name is specified a buffer for STDIN is returned
func GetBufferedReader(fileName string) *bufio.Reader {
	file, err := fileReader(fileName)
	if err != nil {
		fatal("cannot open file for read %s: %v", fileName, err)
		return nil
	}
	return bufio.NewReaderSize(file, defaultReadSize)
}

// fileReader returns a reader for the given file name,
// handling gzipped files if the file extensions is gzip,
// or STDIN if the file name is empty
func fileReader(fileName string) (io.Reader, error) {
	if len(fileName) == 0 {
		// Read from STDIN
		return os.Stdin, nil
	}
	file, err := os.Open(fileName)
	if err != nil {
		return nil, err
	}
	if !strings.HasSuffix(fileName, ".gz") {
		return file, nil
	}
	return gzip.NewReader(file)
}
