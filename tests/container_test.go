package main

import (
	"context"
	"os"
	"testing"
	"time"

	"github.com/stretchr/testify/require"
	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/network"
	"github.com/testcontainers/testcontainers-go/wait"

	"github.com/imagegenius/docker-obico/tests/testhelpers"
)

func Test(t *testing.T) {
	ctx := context.Background()
	variant := os.Getenv("VARIANT")
	if variant == "" {
		variant = "main"
	}
	image := testhelpers.GetTestImage("obico:local-" + variant)
	t.Logf("testing image: %s", image)

	net, err := network.New(ctx)
	require.NoError(t, err)
	t.Cleanup(func() { _ = net.Remove(ctx) })

	redis, err := testcontainers.Run(ctx, "redis:7-alpine",
		network.WithNetwork([]string{"redis"}, net),
		testcontainers.WithWaitStrategy(wait.ForListeningPort("6379/tcp")),
	)
	testcontainers.CleanupContainer(t, redis)
	require.NoError(t, err, "redis failed to start")

	obico, err := testcontainers.Run(ctx, image,
		testcontainers.WithEnv(map[string]string{
			"HOST_IP":   "localhost:3334",
			"REDIS_URL": "redis://redis:6379",
		}),
		testcontainers.WithExposedPorts("3334/tcp"),
		network.WithNetwork([]string{"obico"}, net),
		testcontainers.WithWaitStrategy(
			wait.ForHTTP("/hc/").
				WithPort("3334/tcp").
				WithStartupTimeout(5*time.Minute),
		),
	)
	testcontainers.CleanupContainer(t, obico)
	require.NoError(t, err, "obico failed to come up; check Redis reachability and logs above")
}
