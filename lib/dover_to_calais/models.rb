require 'ohm'
require 'ohm/contrib'

module DoverToCalais
  class EntityModel < Ohm::Model
    attribute :name
    attribute :type
    attribute :calais_id
    set :relations, :RelationModel
    set :events, :EventModel


    index :name
    index :type
    index :calais_id

    def validate
      assert_present :name
      assert_present :type
      assert_present :calais_id
    end

    class RelationModel < Ohm::Model
      include Ohm::DataTypes

      attribute :subject, Type::Hash
      attribute :object, Type::Hash
      attribute :verb
      attribute :detection
      attribute :calais_id
      # reference :entity, :EntityModel

      index :subject

    end #class

    class EventModel < Ohm::Model
      include Ohm::DataTypes
      # attribute :type
      # attribute :info_hash
      attribute :calais_id

      attribute :info_hash, Type::Hash


      # index :type
      # unique :calais_id


    end #class

  end #class




end