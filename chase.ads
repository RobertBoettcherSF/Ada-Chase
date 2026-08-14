--  chase.ads
--  Implementation of the Chase algorithm for database functional dependencies
--  and its variants (Oblivious, Restricted, Core)
--
--  The Chase algorithm tests and enforces implication of data dependencies
--  in database systems. It determines whether a decomposition is lossless
--  by checking if the join of projections can recover the original relation.

with Ada.Containers.Vectors;
with Ada.Containers.Hashed_Sets;
with Ada.Strings.Hash;

package Chase is

   -- ===================================================================
   -- TYPE DEFINITIONS
   -- ===================================================================

   -- Attribute names are represented as strings
   type Attribute is new String;

   -- A value in the tableau can be either a constant (unsubscripted) or a variable (subscripted)
   type Value_Type is (Constant, Variable);

   type Value is record
      Text     : String(1..10);  -- Value text (e.g., "a", "b1", etc.)
      V_Type   : Value_Type;
      Subscript : Integer;         -- For variables: the subscript (0 = no subscript)
   end record;

   -- A tuple in the tableau
   type Tuple is array (Positive range <>) of Value;

   -- A relation schema (set of attributes)
   type Attribute_Set is array (Positive range <>) of Attribute;

   -- A functional dependency: Left -> Right
   type Functional_Dependency is record
      Left  : Attribute_Set;
      Right : Attribute;
   end record;

   -- Set of functional dependencies
   type FD_Set is array (Positive range <>) of Functional_Dependency;

   -- A tableau (matrix of values)
   type Tableau is array (Positive range <>) of Tuple;

   -- A decomposition (set of relation schemas)
   type Decomposition is array (Positive range <>) of Attribute_Set;

   -- ===================================================================
   -- EXCEPTIONS
   -- ===================================================================

   -- Exception raised when attributes are not found
   Attribute_Not_Found : exception;

   -- Exception raised when tableau is empty
   Empty_Tableau : exception;

   -- Exception raised when functional dependency is invalid
   Invalid_FD : exception;

   -- Exception raised when decomposition is invalid
   Invalid_Decomposition : exception;

   -- ===================================================================
   -- MAIN CHASE ALGORITHMS
   -- ===================================================================

   -- Standard Chase algorithm for functional dependencies
   -- Tests whether a decomposition is lossless by chasing the tableau
   -- Parameters:
   --   Original_Tuple : The original tuple to test
   --   FDs : Set of functional dependencies
   --   Decomp : Decomposition of the relation schema
   -- Returns: True if the decomposition is lossless (tuple is recovered)
   function Standard_Chase (
      Original_Tuple : Tuple;
      FDs           : FD_Set;
      Decomp        : Decomposition)
   return Boolean;

   -- Oblivious (Naive) Chase variant
   -- Always adds new witnesses eagerly
   function Oblivious_Chase (
      Original_Tuple : Tuple;
      FDs           : FD_Set;
      Decomp        : Decomposition)
   return Boolean;

   -- Core Chase variant
   -- Tries to minimize the tableau by keeping only the "core" tuples
   function Core_Chase (
      Original_Tuple : Tuple;
      FDs           : FD_Set;
      Decomp        : Decomposition)
   return Boolean;

   -- Restricted Chase for Tuple-Generating Dependencies (TGDs)
   -- More general version that handles existential rules
   function Restricted_Chase_TGD (
      Original_Tuple : Tuple;
      TGDs          : FD_Set;  -- Using FD_Set as placeholder for TGDs
      Decomp        : Decomposition)
   return Boolean;

   -- ===================================================================
   -- TABLEAU OPERATIONS
   -- ===================================================================

   -- Create initial tableau from decomposition
   function Create_Initial_Tableau (
      Original_Tuple : Tuple;
      Decomp        : Decomposition)
   return Tableau;

   -- Apply a single functional dependency to the tableau
   procedure Apply_FD (
      Tableau   : in out Tableau;
      FD        : Functional_Dependency;
      Changed   : out Boolean);

   -- Check if tableau contains the original tuple
   function Contains_Original_Tuple (
      Tableau       : Tableau;
      Original_Tuple : Tuple)
   return Boolean;

   -- Check if two values are equal (considering subscripts)
   function Values_Equal (Left, Right : Value) return Boolean;

   -- ===================================================================
   -- HELPER FUNCTIONS
   -- ===================================================================

   -- Create a constant value
   function Create_Constant (Text : String) return Value;

   -- Create a variable value with subscript
   function Create_Variable (Text : String; Subscript : Integer) return Value;

   -- Get the index of an attribute in a schema
   function Find_Attribute_Index (
      Attributes : Attribute_Set;
      Attr       : Attribute)
   return Integer;

   -- Check if an attribute is in a schema
   function Attribute_In_Schema (
      Attributes : Attribute_Set;
      Attr       : Attribute)
   return Boolean;

   -- Print a tableau for debugging
   procedure Print_Tableau (Tableau : Tableau);

   -- Print a tuple for debugging
   procedure Print_Tuple (T : Tuple);

   -- ===================================================================
   -- VALIDATION FUNCTIONS
   -- ===================================================================

   -- Validate that all FDs are well-formed
   function Validate_FDs (FDs : FD_Set) return Boolean;

   -- Validate that decomposition covers all attributes
   function Validate_Decomposition (
      Decomp     : Decomposition;
      All_Attrs  : Attribute_Set)
   return Boolean;

end Chase;
