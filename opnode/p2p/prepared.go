package p2p

import (
	"errors"
	"fmt"

	"github.com/ethereum/go-ethereum/log"
	"github.com/ethereum/go-ethereum/p2p/discover"
	"github.com/ethereum/go-ethereum/p2p/enode"
	"github.com/libp2p/go-libp2p-core/host"
)

// Prepared provides a p2p host and discv5 service that is already set up.
// This implements SetupP2P.
type Prepared struct {
	HostP2P   host.Host
	LocalNode *enode.LocalNode
	UDPv5     *discover.UDPv5
}

var _ SetupP2P = (*Prepared)(nil)

func (p *Prepared) Check() error {
	if (p.LocalNode == nil) != (p.UDPv5 == nil) {
		return fmt.Errorf("inconsistent discv5 setup: %v <> %v", p.LocalNode, p.UDPv5)
	}
	if p.LocalNode != nil && p.HostP2P == nil {
		return errors.New("cannot provide discovery without p2p host")
	}
	return nil
}

// Host creates a libp2p host service. Returns nil, nil if p2p is disabled.
func (p *Prepared) Host() (host.Host, error) {
	return p.HostP2P, nil
}

// Discovery creates a disc-v5 service. Returns nil, nil, nil if discovery is disabled.
func (p *Prepared) Discovery(log log.Logger) (*enode.LocalNode, *discover.UDPv5, error) {
	return p.LocalNode, p.UDPv5, nil
}
