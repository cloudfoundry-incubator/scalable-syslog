package controller_test

import (
	"context"

	"github.com/cloudfoundry-incubator/scalable-syslog/adapter/internal/controller"
	v1 "github.com/cloudfoundry-incubator/scalable-syslog/api/v1"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("Controller", func() {
	var (
		mockStore *mockBindingStore
		c         *controller.Controller
	)

	BeforeEach(func() {
		mockStore = newMockBindingStore()
		c = controller.New(mockStore)
	})

	It("returns a list of known bindings", func() {
		mockStore.ListOutput.Bindings <- []*v1.Binding{nil, nil}
		resp, err := c.ListBindings(context.Background(), new(v1.ListBindingsRequest))

		Expect(err).ToNot(HaveOccurred())
		Expect(resp.Bindings).To(HaveLen(2))
	})

	It("adds new bindings to the store", func() {
		binding := &v1.Binding{
			AppId:    "some-app-id",
			Hostname: "some-host",
			Drain:    "some.url",
		}
		_, err := c.CreateBinding(context.Background(), &v1.CreateBindingRequest{
			Binding: binding,
		})

		Expect(err).ToNot(HaveOccurred())
		Expect(mockStore.AddInput.Binding).To(Receive(Equal(binding)))
	})

	It("deletes existing bindings to the store", func() {
		binding := &v1.Binding{
			AppId:    "some-app-id",
			Hostname: "some-host",
			Drain:    "some.url",
		}
		_, err := c.DeleteBinding(context.Background(), &v1.DeleteBindingRequest{
			Binding: binding,
		})

		Expect(err).ToNot(HaveOccurred())
		Expect(mockStore.DeleteInput.Binding).To(Receive(Equal(binding)))
	})
})
