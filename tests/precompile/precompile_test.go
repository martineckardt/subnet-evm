// Copyright (C) 2023, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

package precompile

import (
	"os"
	"testing"

	ginkgo "github.com/onsi/ginkgo/v2"
	"github.com/onsi/gomega"

	// Import the solidity package, so that ginkgo maps out the tests declared within the package
	_ "github.com/ava-labs/subnet-evm/tests/precompile/solidity"
	"github.com/ava-labs/subnet-evm/tests/utils"
)

func init() {
	utils.RegisterNodeRun()
}

func TestE2E(t *testing.T) {
	if basePath := os.Getenv("TEST_SOURCE_ROOT"); basePath != "" {
		os.Chdir(basePath)
	}
	gomega.RegisterFailHandler(ginkgo.Fail)
	ginkgo.RunSpecs(t, "subnet-evm precompile ginkgo test suite")
}
