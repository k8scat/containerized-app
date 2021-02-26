package router

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"

	"github.com/iris-contrib/middleware/cors"
	"github.com/kataras/iris/v12"
)

func Run(hostPort string) {
	app := iris.New()
	app.Use(iris.Compression)

	crs := cors.New(cors.Options{
		AllowedOrigins:   []string{"*"},
		AllowCredentials: true,
		AllowedMethods:   []string{iris.MethodGet, iris.MethodPost, iris.MethodOptions},
	})
	api := app.Party("/api", crs).AllowMethods(iris.MethodOptions)
	{
		api.Get("/hitokoto", getHitokoto)
	}

	app.Listen(hostPort)
}

func getHitokoto(ctx iris.Context) {
	resp, err := http.Get("https://v1.hitokoto.cn")
	var res map[string]interface{}
	if err != nil {
		res = map[string]interface{}{
			"code": iris.StatusInternalServerError,
			"err":  fmt.Sprintf("get https://v1.hitokoto.cn failed: %v", err),
		}
	}
	b, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		res = map[string]interface{}{
			"code": iris.StatusInternalServerError,
			"err":  fmt.Sprintf("read response body failed: %v", err),
		}
	}
	var data struct {
		Hitokoto string `json:"hitokoto"`
	}
	if err := json.Unmarshal(b, &data); err != nil {
		res = map[string]interface{}{
			"code": iris.StatusInternalServerError,
			"err":  fmt.Sprintf("unmarshal response body failed: %v", err),
		}
	}
	res = map[string]interface{}{
		"code":     iris.StatusOK,
		"hitokoto": data.Hitokoto,
	}
	ctx.JSON(res)
}
