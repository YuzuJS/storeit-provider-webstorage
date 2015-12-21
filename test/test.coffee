Provider = require("..")
Q = require("q")

FooSerializer = (name) ->
    @name = name || "foo"
    @serialize = (value) ->
        return JSON.stringify(value)
    @deserialize = (value) ->
        return if value then JSON.parse(value) else null
    return

provider = null
fooSerializer = null
aSerializer = null
bSerializer = null
localStorage = null
key = "k"
value = "v"
serializedValue = (new FooSerializer).serialize(value)

describe "Test that the WebStorage provider...", ->

    beforeEach ->
        # mock up a serializer
        fooSerializer = new FooSerializer

        options =
            localOrSessionStorage: null,
            allSerializers: [fooSerializer],
            metadataSerializerName: "foo",
            preferredItemSerializerName: "foo"

        provider = new Provider options

    it "implements the correct properties/methods (before initialization)", ->
        provider.should.have.property("metadataSerializer")
        provider.should.have.property("itemSerializer")
        provider.should.respondTo("removeItem")
        provider.should.respondTo("setMetadata")
        provider.should.respondTo("getMetadata")
        provider.should.respondTo("setItem")
        provider.should.respondTo("getItem")

    it "is named correctly", ->
        provider.should.have.property("name")
        provider.name.should.equal("WebStorageProvider")

    it "itemSerializer is set correctly", ->
        provider.should.have.property("itemSerializer")
        provider.itemSerializer.should.equal("foo")

    it "metadataSerializer is set correctly", ->
        provider.should.have.property("metadataSerializer")
        provider.metadataSerializer.should.equal("foo")

describe "Test that the WebStorage provider (initialized)...", ->

    beforeEach ->
        # mock up a serializer
        aSerializer = new FooSerializer("a")
        bSerializer = new FooSerializer("b")

        # mock up localStorage
        localStorage =
            removeItem: (key) ->
            setItem: (key, value) ->
            getItem: (key) ->
                return serializedValue

        options =
            localOrSessionStorage: localStorage,
            allSerializers: [aSerializer, bSerializer],
            metadataSerializerName: "a",
            preferredItemSerializerName: "a"

        provider = new Provider options
        provider.itemSerializer = "b" # override with "b"

    it "implements additional properties/methods", ->
        provider.should.respondTo("setItem")
        provider.should.respondTo("getItem")
        provider.should.have.property("itemSerializer")
        provider.itemSerializer.should.equal("b")
        provider.metadataSerializer.should.equal("a")

    describe "and when calling setItem", ->
        beforeEach (done) ->
            sinon.spy(localStorage, "setItem")
            sinon.spy(aSerializer, "serialize")
            sinon.spy(bSerializer, "serialize")
            provider.setItem(key, value).then(done, done)

        it "should call localStorage.setItem", ->
            localStorage.setItem.should.have.been.calledWith(key, serializedValue)

        it "should call provider.serialize", ->
            bSerializer.serialize.should.have.been.calledWith(value)
            aSerializer.serialize.should.not.have.been.called

    describe "and when calling getItem", ->
        beforeEach (done) ->
            sinon.spy(localStorage, "getItem")
            sinon.spy(aSerializer, "deserialize")
            sinon.spy(bSerializer, "deserialize")
            provider.getItem(key).then(
                (result) =>
                    @result = result
                    done()
                )

        it "should call localStorage.getItem", ->
            localStorage.getItem.should.have.been.calledWith(key)

        it "should call provider.deserialize", ->
            bSerializer.deserialize.should.have.been.calledWith(serializedValue)
            aSerializer.deserialize.should.not.have.been.called

        it "should return the correct value", ->
            @result.should.equal(value)
