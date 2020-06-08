package main

import (
	"log"
	"time"
	"math"
	"strconv"
	"net/http"

	_ "github.com/go-sql-driver/mysql"

	"github.com/gin-gonic/gin"
	"github.com/jmoiron/sqlx"
	"github.com/golang/geo/s2"
	"github.com/golang/geo/s1"
)
const (
	EarthRadiusKM = 6371.01
	PricePerKM = 10
)

// We need an object that implements the http.Handler interface.
// Therefore we need a type for which we implement the ServeHTTP method.
// We just use a map here, in which we map host names (with port) to http.Handlers
type HostSwitch map[string]http.Handler

// Implement the ServeHTTP method on our new type
func (hs HostSwitch) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	// Check if a http.Handler is registered for the given host.
	// If yes, use it to handle the request.
	if handler := hs[r.Host]; handler != nil {
		handler.ServeHTTP(w, r)
	} else {
		// Handle host names for which no handler is registered
		http.Error(w, "Forbidden", 403) // Or Redirect?
	}
}

func main() {
	db, err := sqlx.Connect("mysql", "local_orders:local_orders@tcp(mysql:3306)/local_orders?charset=utf8mb4&parseTime=true")
    if err != nil {
        log.Fatalln(err)
	}
	defer db.Close()

	r := gin.Default()
	r.POST("/rpc/createOrder", createOrder(db))
	r.Run(":80")
}

type LatLng struct {
	Lat float64	`json:"lat"`
	Lng float64 `json:"lng"`
}

type Order struct {
	ID uint32		`db:"id" json:"id"`
	FromLat float64	`db:"from_lat" json:"fromLat"`
	FromLng float64	`db:"from_lng" json:"fromLng"`
	ToLat float64	`db:"to_lat" json:"toLat"`
	ToLng float64	`db:"to_lng" json:"toLng"`
	Status int	`db:"status" json:"status"`
	TotalPrice string	`db:"total_price" json:"totalPrice"`
	OrderDatetime time.Time	`db:"order_datetime" json:"orderDateTime"`
}

func createOrder(db *sqlx.DB) func(c *gin.Context) {
	return func(c *gin.Context) {
		type requestBody struct {
			From	LatLng	`json:"from"`
			To		LatLng	`json:"to"`
		}
		req := requestBody{}
		err := c.Bind(&req)
		if err != nil {
			c.Status(400)
			return
		}

		startLocation := s2.LatLng{
			Lat: s1.Angle(req.From.Lat * float64(s1.Degree)),
			Lng: s1.Angle(req.From.Lng * float64(s1.Degree)),
		}
		endLocation := s2.LatLng{
			Lat: s1.Angle(req.To.Lat * float64(s1.Degree)),
			Lng: s1.Angle(req.To.Lng * float64(s1.Degree)),
		}

		angle := startLocation.Distance(endLocation)
		distanceMeters := EarthRadiusKM * 1000 * float64(angle)
		price := int(math.Ceil(distanceMeters / 1000)) * PricePerKM

		order := Order{
			FromLat: req.From.Lat,
			FromLng: req.From.Lng,
			ToLat: req.To.Lat,
			ToLng: req.To.Lng,
			TotalPrice: strconv.Itoa(price),
		}
		log.Printf("order: %v\n", order)
		result, err := db.NamedExec(`
			INSERT INTO orders 
			(from_lat, from_lng, to_lat, to_lng, total_price) 
			VALUES 
			(:from_lat, :from_lng, :to_lat, :to_lng, :total_price)
		`, order)
		if err != nil {
			log.Printf("ERR: %s", err)
		}
		orderID, err := result.LastInsertId()
		if err != nil {
			log.Printf("ERR: %s", err)
		}
		order.ID = uint32(orderID)

		c.JSON(200, gin.H{
			"order": gin.H{
				"id": order.ID,
				"from": gin.H{
					"lat": order.FromLat,
					"lng": order.FromLng,
				},
				"to": gin.H{
					"lat": order.ToLat,
					"lng": order.ToLng,
				},
				"totalPrice": order.TotalPrice,
			},
		})
	}
}