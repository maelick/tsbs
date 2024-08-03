package utils

import (
	"bufio"
	"compress/gzip"
	"fmt"
	"io"
	"os"
	"strings"
)

const (
	defaultWriteSize = 4 << 20 // 4 MB
)

// GetBufferedWriter returns a buffered Writer alongside the underlying WriteCloser to be used when saving data or queries.
// If a fileName is given, the output will be written to that file, otherwise it will be written to the fallback Writer.
// If the fileName has a .gz extension, the output will be gzipped.
func GetBufferedWriter(fileName string, fallback io.WriteCloser) (*bufio.Writer, io.WriteCloser, error) {
	file, err := fileWriter(fileName, fallback)
	if err != nil {
		return nil, file, fmt.Errorf("cannot open file for write %s: %w", fileName, err)
	}
	return bufio.NewWriterSize(file, defaultWriteSize), file, nil
}

// fileReader returns a reader for the given file name,
// handling gzipped files if the file extensions is gzip,
// or fallback if the file name is empty.
func fileWriter(fileName string, fallback io.WriteCloser) (io.WriteCloser, error) {
	if len(fileName) == 0 {
		return fallback, nil
	}
	file, err := os.Create(fileName)
	if err != nil {
		return nil, err
	}
	if !strings.HasSuffix(fileName, ".gz") {
		return file, nil
	}
	return gzip.NewWriter(file), nil
}
