"use strict";

var serializers = {};

module.exports = function WebStorageProvider(options) {
    var that = this;
    var itemSerializer = null;
    var localOrSessionStorage = options.localOrSessionStorage;

    options.allSerializers.forEach(function (serializer) {
        serializers[serializer.name] = serializer;
    });

    var metadataSerializer = serializers[options.metadataSerializerName];

    function setItemSerializer(value) {
        itemSerializer = serializers[value || options.preferredItemSerializerName];
        that.setItem = setItem.bind(null, itemSerializer);
        that.getItem = getItem.bind(null, itemSerializer);
    }

    Object.defineProperty(that, "name", {
        value: "WebStorageProvider",
        enumerable: true
    });

    Object.defineProperty(that, "metadataSerializer", {
        value: options.metadataSerializerName,
        enumerable: true
    });

    Object.defineProperty(that, "itemSerializer", {
        get: function () {
            return itemSerializer ? itemSerializer.name : null;
        },
        set: setItemSerializer
    });

    that.removeItem = function (key) {
        localOrSessionStorage.removeItem(key);
    };

    function setItem(serializer, key, value) {
        localOrSessionStorage.setItem(key, serializer.serialize(value));
    }

    function getItem(serializer, key) {
        return serializer.deserialize(localOrSessionStorage.getItem(key));
    }

    that.setMetadata = setItem.bind(null, metadataSerializer);
    that.getMetadata = getItem.bind(null, metadataSerializer);

    setItemSerializer(null); // Default to using the preferredItemSerializer.
};
