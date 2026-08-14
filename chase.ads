--  chase.ads
package Chase is
   type Attribute is new String;
   type Value_Kind is (Literal_Value, Variable_Value);
   
   type Value is record
      Text : String(1..10);
      V_Kind : Value_Kind;
      Subscript : Integer;
   end record;

   Max_Attributes : constant Integer := 20;
   Max_Tuples : constant Integer := 100;
   Max_FDs : constant Integer := 50;
   Max_Schemas : constant Integer := 20;

   type Tuple is array (1..Max_Attributes) of Value;
   type Attribute_List is array (1..Max_Attributes) of Attribute;
   
   type Functional_Dependency is record
      Left : Attribute_List;
      Left_Length : Integer;
      Right : Attribute;
   end record;

   type FD_List is array (1..Max_FDs) of Functional_Dependency;
   type Tableau is array (1..Max_Tuples) of Tuple;
   type Decomposition is array (1..Max_Schemas) of Attribute_List;

   -- Exceptions
   Attribute_Not_Found : exception;
   Empty_Tableau : exception;
   Invalid_FD : exception;
   Invalid_Decomposition : exception;

   -- Main algorithms
   function Standard_Chase (Original_Tuple : Tuple; FDs : FD_List; FDs_Length : Integer;
                          Decomp : Decomposition; Decomp_Length : Integer; Tuple_Length : Integer) return Boolean;
   function Oblivious_Chase (Original_Tuple : Tuple; FDs : FD_List; FDs_Length : Integer;
                           Decomp : Decomposition; Decomp_Length : Integer; Tuple_Length : Integer) return Boolean;
   function Core_Chase (Original_Tuple : Tuple; FDs : FD_List; FDs_Length : Integer;
                      Decomp : Decomposition; Decomp_Length : Integer; Tuple_Length : Integer) return Boolean;
   function Restricted_Chase_TGD (Original_Tuple : Tuple; TGDs : FD_List; TGDs_Length : Integer;
                                Decomp : Decomposition; Decomp_Length : Integer; Tuple_Length : Integer) return Boolean;

   -- Tableau operations
   procedure Create_Initial_Tableau (Original_Tuple : Tuple; Decomp : Decomposition; Decomp_Length : Integer;
                                    Tuple_Length : Integer; Result : out Tableau; Result_Length : out Integer);
   procedure Apply_FD (T : in out Tableau; T_Length : Integer; FD : Functional_Dependency; Tuple_Length : Integer; Changed : out Boolean);
   function Contains_Original_Tuple (T : Tableau; T_Length : Integer; Original_Tuple : Tuple; Tuple_Length : Integer) return Boolean;
   function Values_Equal (Left, Right : Value) return Boolean;

   -- Helpers
   function Create_Literal (Text : String) return Value;
   function Create_Variable (Text : String; Subscript : Integer) return Value;
   function Find_Attribute_Index (Attributes : Attribute_List; Attr_Length : Integer; Attr : Attribute) return Integer;
   function Attribute_In_Schema (Attributes : Attribute_List; Attr_Length : Integer; Attr : Attribute) return Boolean;

   -- Validation
   function Validate_FDs (FDs : FD_List; FDs_Length : Integer) return Boolean;
   function Validate_Decomposition (Decomp : Decomposition; Decomp_Length : Integer;
                                    All_Attrs : Attribute_List; All_Attrs_Length : Integer) return Boolean;
end Chase;
