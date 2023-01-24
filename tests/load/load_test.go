// Copyright (C) 2019-2022, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// e2e implements the e2e tests.
package precompile

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"testing"
	"time"

	"github.com/ava-labs/avalanchego/api/health"
	"github.com/ava-labs/subnet-evm/tests/precompile/utils"
	"github.com/ethereum/go-ethereum/log"
	"github.com/go-cmd/cmd"
	ginkgo "github.com/onsi/ginkgo/v2"
	"github.com/onsi/gomega"

	_ "github.com/ava-labs/subnet-evm/tests/precompile/solidity"
)

var startCmd *cmd.Cmd

func TestE2E(t *testing.T) {
	gomega.RegisterFailHandler(ginkgo.Fail)
	ginkgo.RunSpecs(t, "subnet-evm load test suite")
}

// BeforeSuite starts an AvalancheGo process to use for the e2e tests
var _ = ginkgo.BeforeSuite(func() {
	ctx, cancel := context.WithTimeout(context.Background(), time.Minute)
	defer cancel()

	var err error
	wd, err := os.Getwd()
	gomega.Expect(err).Should(gomega.BeNil())
	log.Info("Starting AvalancheGo node", "wd", wd)
	startCmd, err = utils.RunCommand("./scripts/run.sh")
	gomega.Expect(err).Should(gomega.BeNil())

	// Assumes that startCmd will launch a node with HTTP Port at [utils.DefaultLocalNodeURI]
	healthClient := health.NewClient(utils.DefaultLocalNodeURI)
	healthy, err := health.AwaitReady(ctx, healthClient, 5*time.Second)
	gomega.Expect(err).Should(gomega.BeNil())
	gomega.Expect(healthy).Should(gomega.BeTrue())
	log.Info("AvalancheGo node is healthy")
})

var _ = ginkgo.Describe("[Precompiles]", ginkgo.Ordered, func() {
	ginkgo.It("basic load test", ginkgo.Label("load"), func() {
		// client := health.NewClient(utils.DefaultLocalNodeURI)

		// err = os.Setenv("RPC_URI", rpcURI)
		// gomega.Expect(err).Should(gomega.BeNil())
		cmd := exec.Command("./scripts/run_simulator.sh")
		log.Info("Running load simulator script", "cmd", cmd.String())

		out, err := cmd.CombinedOutput()
		fmt.Printf("\nCombined output:\n\n%s\n", string(out))
		gomega.Expect(err).Should(gomega.BeNil())
	})
})

var _ = ginkgo.AfterSuite(func() {
	gomega.Expect(startCmd).ShouldNot(gomega.BeNil())
	gomega.Expect(startCmd.Stop()).Should(gomega.BeNil())
	// TODO add a new node to bootstrap off of the existing node and ensure it can bootstrap all subnets
	// created during the test
})
