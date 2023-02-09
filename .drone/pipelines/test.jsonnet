local build_image = import '../util/build_image.jsonnet';
local pipelines = import '../util/pipelines.jsonnet';

[
  pipelines.linux('Lint') {
    trigger: {
      event: ['pull_request'],
    },
    steps: [{
      name: 'Lint',
      // TODO(rfratto): the build image is swapped out for golangci-lint while
      // we're waiting for golangci-lint to support Go 1.20. Replace back with
      // build_image.linux when it works again.
      image: 'golangci/golangci-lint:v1.50.1',
      commands: [
        'apt-get update -y && apt-get install -y libsystemd-dev',
        'make lint',
      ],
    }],
  },

  pipelines.linux('Test') {
    trigger: {
      event: ['pull_request'],
    },
    steps: [{
      name: 'Run Go tests',
      image: build_image.linux,
      volumes: [{
        name: 'docker',
        path: '/var/run/docker.sock',
      }],

      commands: [
        // The operator tests require K8S_USE_DOCKER_NETWORK=1 to be set when
        // tests are being run inside of a Docker container so it can access the
        // created k3d cluster properly.
        'K8S_USE_DOCKER_NETWORK=1 make test',
      ],
    }],
    volumes: [{
      name: 'docker',
      host: {
        path: '/var/run/docker.sock',
      },
    }],
  },

  pipelines.windows('Test (Windows)') {
    trigger: {
      event: ['pull_request'],
    },
    steps: [{
      name: 'Run Go tests',
      image: build_image.windows,
      environment: {
        ASSUME_NO_MOVING_GC_UNSAFE_RISK_IT_WITH: 'go1.20',
      },
      commands: ['go test -tags="nodocker,nonetwork" ./...'],
    }],
  },
]