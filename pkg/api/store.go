package api

import (
	"crypto/sha1"
	"encoding/hex"
	"io/ioutil"
	"net/http"
	"path"

	"go.uber.org/zap"
	"github.com/gorilla/mux"
)

func (s *Server) storeWriteHandler(w http.ResponseWriter, r *http.Request) {

	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		s.ErrorResponse(w, r, "reading the request body failed", http.StatusBadRequest)
		return
	}

	hash := hash(string(body))
	err = ioutil.WriteFile(path.Join(s.config.DataPath, hash), body, 0644)
	if err != nil {
		s.logger.Warn("writing file failed", zap.Error(err), zap.String("file", path.Join(s.config.DataPath, hash)))
		s.ErrorResponse(w, r, "writing file failed", http.StatusInternalServerError)
		return
	}
	s.JSONResponseCode(w, r,  map[string]string{"hash": hash}, http.StatusAccepted)
}

func (s *Server) storeReadHandler(w http.ResponseWriter, r *http.Request) {
	hash := mux.Vars(r)["hash"]
	content, err := ioutil.ReadFile(path.Join(s.config.DataPath, hash))
	if err != nil {
		s.logger.Warn("reading file failed", zap.Error(err), zap.String("file", path.Join(s.config.DataPath, hash)))
		s.ErrorResponse(w, r, "reading file failed", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusAccepted)
	w.Write([]byte(content))
}

func hash(input string) string {
	h := sha1.New()
	h.Write([]byte(input))
	return hex.EncodeToString(h.Sum(nil))
}
