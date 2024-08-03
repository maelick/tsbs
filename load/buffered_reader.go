package load

import (
	"bufio"
	"os"

	"github.com/timescale/tsbs/internal/utils"
)

// GetBufferedReader returns the buffered Reader that should be used by the file loader
// if no file name is specified a buffer for STDIN is returned
func GetBufferedReader(fileName string) *bufio.Reader {
	file, err := utils.GetBufferedReader(fileName, os.Stdin)
	if err != nil {
		fatal("cannot open file for read %s: %v", fileName, err)
		return nil
	}
	return file
}
