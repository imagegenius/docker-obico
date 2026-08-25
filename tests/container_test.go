package main

import (
	"context"
	"io"
	"os"
	"testing"
	"time"

	"github.com/moby/moby/api/types/container"
	"github.com/stretchr/testify/require"
	"github.com/testcontainers/testcontainers-go"
	tcexec "github.com/testcontainers/testcontainers-go/exec"
	"github.com/testcontainers/testcontainers-go/network"
	"github.com/testcontainers/testcontainers-go/wait"

	helpers "github.com/hydazz/containers/tests"
)

func Test(t *testing.T) {
	ctx := context.Background()
	variant := os.Getenv("VARIANT")
	if variant == "" {
		variant = "main"
	}
	image := helpers.GetTestImage("obico:local-" + variant)
	t.Logf("testing image: %s", image)

	modelLibrary := "/darknet/libdarknet_cpu.so"
	containerOptions := []testcontainers.ContainerCustomizer{
		testcontainers.WithEnv(map[string]string{
			"REDIS_URL": "redis://redis:6379",
		}),
		testcontainers.WithExposedPorts("3334/tcp"),
	}
	if variant == "cuda" && os.Getenv("TEST_GPU") == "true" {
		modelLibrary = "/darknet/libdarknet_gpu.so"
		containerOptions = append(containerOptions,
			testcontainers.WithHostConfigModifier(func(hostConfig *container.HostConfig) {
				hostConfig.DeviceRequests = []container.DeviceRequest{{
					Driver:       "nvidia",
					Count:        -1,
					Capabilities: [][]string{{"gpu"}},
				}}
			}),
		)
	}

	net, err := network.New(ctx)
	require.NoError(t, err)
	t.Cleanup(func() { _ = net.Remove(ctx) })

	redis, err := testcontainers.Run(ctx, "redis:7-alpine",
		network.WithNetwork([]string{"redis"}, net),
		testcontainers.WithWaitStrategy(wait.ForListeningPort("6379/tcp")),
	)
	testcontainers.CleanupContainer(t, redis)
	require.NoError(t, err, "redis failed to start")

	containerOptions = append(containerOptions,
		network.WithNetwork([]string{"obico"}, net),
		testcontainers.WithWaitStrategy(
			wait.ForAll(
				wait.ForHTTP("/hc/").WithPort("3334/tcp"),
			).WithDeadline(5*time.Minute),
		),
	)
	obico, err := testcontainers.Run(ctx, image, containerOptions...)
	testcontainers.CleanupContainer(t, obico)
	require.NoError(t, err, "obico failed to come up; check Redis reachability and logs above")

	exitCode, output, err := obico.Exec(ctx, []string{
		"bash", "-c",
		`for maps in /proc/[0-9]*/maps; do if grep -Fq "` + modelLibrary + `" "$maps" 2>/dev/null; then echo "$maps"; exit 0; fi; done; exit 1`,
	}, tcexec.WithUser("abc"), tcexec.Multiplexed())
	require.NoError(t, err)
	mappedBy, err := io.ReadAll(output)
	require.NoError(t, err)
	require.Equalf(t, 0, exitCode, "ML worker did not load %s; mapped by: %s", modelLibrary, mappedBy)
}
