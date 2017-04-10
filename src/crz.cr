require "./crz/*"

module CRZ
  include CRZ::Containers
  include CRZ::Monad::Macros
  include CRZ::Prelude
end
