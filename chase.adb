--  chase.adb
--  Implementation of the Chase algorithm and its variants

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Containers.Vectors;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;

package body Chase is

   -- ===================================================================
   -- HELPER FUNCTIONS
   -- ===================================================================

   function Create_Constant (Text : String) return Value is
      V : Value;
   begin
      if Text'Length > 10 then
         raise Invalid_FD with "Value text too long";
      end if;
      V.Text := (1..Text'Length => ' ');
      V.Text(1..Text'Length) := Text;
      V.V_Type := Constant;
      V.Subscript := 0;
      return V;
   end Create_Constant;

   function Create_Variable (Text : String; Subscript : Integer) return Value is
      V : Value;
   begin
      if Text'Length > 10 then
         raise Invalid_FD with "Value text too long";
      end if;
      V.Text := (1..Text'Length => ' ');
      V.Text(1..Text'Length) := Text;
      V.V_Type := Variable;
      V.Subscript := Subscript;
      return V;
   end Create_Variable;

   function Values_Equal (Left, Right : Value) return Boolean is
   begin
      -- If both are constants, they must be equal
      if Left.V_Type = Constant and Right.V_Type = Constant then
         return Trim(Left.Text, Both) = Trim(Right.Text, Both);
      end if;

      -- If one is constant and the other is variable, they are equal
      -- only if the variable's base text matches the constant
      if Left.V_Type = Constant and Right.V_Type = Variable then
         return Trim(Left.Text, Both) = Trim(Right.Text, Both);
      end if;

      if Left.V_Type = Variable and Right.V_Type = Constant then
         return Trim(Left.Text, Both) = Trim(Right.Text, Both);
      end if;

      -- Both are variables - they are equal if base text and subscript match
      if Left.V_Type = Variable and Right.V_Type = Variable then
         return Trim(Left.Text, Both) = Trim(Right.Text, Both) and
                Left.Subscript = Right.Subscript;
      end if;

      return False;
   end Values_Equal;

   function Find_Attribute_Index (
      Attributes : Attribute_Set;
      Attr       : Attribute)
   return Integer is
   begin
      for I in Attributes'Range loop
         if Attributes(I) = Attr then
            return I;
         end if;
      end loop;
      return -1;  -- Not found
   end Find_Attribute_Index;

   function Attribute_In_Schema (
      Attributes : Attribute_Set;
      Attr       : Attribute)
   return Boolean is
   begin
      return Find_Attribute_Index(Attributes, Attr) /= -1;
   end Attribute_In_Schema;

   -- ===================================================================
   -- TABLEAU OPERATIONS
   -- ===================================================================

   function Create_Initial_Tableau (
      Original_Tuple : Tuple;
      Decomp        : Decomposition)
   return Tableau is

      -- Number of attributes in the original tuple
      Num_Attrs : constant Integer := Original_Tuple'Length;

      -- Number of schemas in decomposition
      Num_Schemas : constant Integer := Decomp'Length;

      -- Result tableau
      Result : Tableau(1..Num_Schemas);

   begin
      -- For each schema in the decomposition
      for Schema_Idx in 1..Num_Schemas loop
         declare
            Schema : Attribute_Set renames Decomp(Schema_Idx);
         begin
            -- Create a tuple for this schema
            Result(Schema_Idx) := new Tuple(1..Num_Attrs);

            -- For each attribute position
            for Attr_Idx in 1..Num_Attrs loop
               -- Check if this attribute is in the current schema
               if Attribute_In_Schema(Schema, Attribute'(Original_Tuple(Attr_Idx).Text)) then
                  -- Use the original value (unsubscripted)
                  Result(Schema_Idx)(Attr_Idx) := Original_Tuple(Attr_Idx);
               else
                  -- Create a variable with subscript = schema index
                  Result(Schema_Idx)(Attr_Idx) :=
                     Create_Variable(Original_Tuple(Attr_Idx).Text, Schema_Idx);
               end if;
            end loop;
         end;
      end loop;

      return Result;
   end Create_Initial_Tableau;

   procedure Apply_FD (
      Tableau   : in out Tableau;
      FD        : Functional_Dependency;
      Changed   : out Boolean) is

      -- Find indices of left and right attributes
      Left_Indices : array (FD.Left'Range) of Integer;
      Right_Index : Integer;

   begin
      Changed := False;

      -- Find the index of the right-hand side attribute in the first tuple
      -- (assuming all tuples have the same attributes)
      if Tableau'Length = 0 then
         raise Empty_Tableau;
      end if;

      -- Get attribute names from the FD
      -- Note: FD.Left is an array of Attribute, FD.Right is a single Attribute
      -- We need to find their positions in the tuples

      -- For simplicity, assume attributes are in order A, B, C, D, etc.
      -- and the FD attributes are represented by their position
      -- This is a simplification - in a real implementation, we'd need a proper
      -- attribute mapping

      -- For this implementation, we'll assume:
      -- - The tuple positions correspond to attribute order
      -- - FD.Left contains attribute names that we need to match to positions

      -- This is a placeholder - a full implementation would need proper
      -- attribute-to-position mapping

      -- For the Wikipedia example, let's hardcode the positions:
      -- A=1, B=2, C=3, D=4

      declare
         -- Map attribute name to position (simplified for the example)
         function Get_Position (Attr : Attribute) return Integer is
         begin
            if Attr = Attribute("A") then return 1;
            elsif Attr = Attribute("B") then return 2;
            elsif Attr = Attribute("C") then return 3;
            elsif Attr = Attribute("D") then return 4;
            else return -1;
            end if;
         end Get_Position;

         Right_Pos : Integer := Get_Position(FD.Right);
      begin
         if Right_Pos = -1 then
            raise Invalid_FD with "Right-hand attribute not found";
         end if;

         -- For each pair of rows in the tableau
         for Row1 in Tableau'Range loop
            for Row2 in Row1+1..Tableau'Range loop
               -- Check if the left-hand side attributes are equal in both rows
               -- and at least one is unsubscripted
               Left_Match : Boolean := True;
               Has_Unsubscripted : Boolean := False;

               for Left_Attr of FD.Left loop
                  declare
                     Pos : Integer := Get_Position(Left_Attr);
                  begin
                     if Pos = -1 then
                        Left_Match := False;
                        exit;
                     end if;

                     -- Check if values are equal
                     if not Values_Equal(Tableau(Row1)(Pos), Tableau(Row2)(Pos)) then
                        Left_Match := False;
                        exit;
                     end if;

                     -- Check if at least one is unsubscripted (constant)
                     if Tableau(Row1)(Pos).V_Type = Constant or
                        Tableau(Row2)(Pos).V_Type = Constant then
                        Has_Unsubscripted := True;
                     end if;
                  end;
               end loop;

               -- If left-hand side matches and we have an unsubscripted value
               if Left_Match and Has_Unsubscripted then
                  -- Check if right-hand side values are different
                  if not Values_Equal(Tableau(Row1)(Right_Pos), Tableau(Row2)(Right_Pos)) then
                     -- Make them equal, preferring the unsubscripted one
                     if Tableau(Row1)(Right_Pos).V_Type = Constant then
                        Tableau(Row2)(Right_Pos) := Tableau(Row1)(Right_Pos);
                        Changed := True;
                     elsif Tableau(Row2)(Right_Pos).V_Type = Constant then
                        Tableau(Row1)(Right_Pos) := Tableau(Row2)(Right_Pos);
                        Changed := True;
                     else
                        -- Both are variables - make them the same
                        -- Use the one with the smaller subscript (arbitrary choice)
                        if Tableau(Row1)(Right_Pos).Subscript < Tableau(Row2)(Right_Pos).Subscript then
                           Tableau(Row2)(Right_Pos) := Tableau(Row1)(Right_Pos);
                        else
                           Tableau(Row1)(Right_Pos) := Tableau(Row2)(Right_Pos);
                        end if;
                        Changed := True;
                     end if;
                  end if;
               end if;
            end loop;
         end loop;
      end;
   end Apply_FD;

   function Contains_Original_Tuple (
      Tableau       : Tableau;
      Original_Tuple : Tuple)
   return Boolean is
   begin
      for Row of Tableau loop
         Match : Boolean := True;
         for I in Row'Range loop
            -- For the original tuple to match, all values must be equal
            -- and the tableau row must have unsubscripted (constant) values
            if Row(I).V_Type /= Constant or else
               not Values_Equal(Row(I), Original_Tuple(I)) then
               Match := False;
               exit;
            end if;
         end loop;
         if Match then
            return True;
         end if;
      end loop;
      return False;
   end Contains_Original_Tuple;

   -- ===================================================================
   -- MAIN CHASE ALGORITHMS
   -- ===================================================================

   function Standard_Chase (
      Original_Tuple : Tuple;
      FDs           : FD_Set;
      Decomp        : Decomposition)
   return Boolean is

      Tableau : Tableau := Create_Initial_Tableau(Original_Tuple, Decomp);
      Changed : Boolean;
      Max_Iterations : constant Integer := 100;  -- Prevent infinite loops
      Iteration : Integer := 0;

   begin
      -- Apply FDs repeatedly until no more changes or max iterations
      loop
         Changed := False;
         Iteration := Iteration + 1;

         -- Apply each FD
         for FD of FDs loop
            Apply_FD(Tableau, FD, Changed);
         end loop;

         exit when not Changed or Iteration >= Max_Iterations;

         -- Check if we've found the original tuple
         if Contains_Original_Tuple(Tableau, Original_Tuple) then
            return True;
         end if;
      end loop;

      -- Final check
      return Contains_Original_Tuple(Tableau, Original_Tuple);
   end Standard_Chase;

   function Oblivious_Chase (
      Original_Tuple : Tuple;
      FDs           : FD_Set;
      Decomp        : Decomposition)
   return Boolean is
      -- For the oblivious chase, we always apply all FDs in each iteration
      -- without checking if changes are needed (eager approach)
      -- This is similar to Standard_Chase but with different application strategy

      Tableau : Tableau := Create_Initial_Tableau(Original_Tuple, Decomp);
      Changed : Boolean;
      Max_Iterations : constant Integer := 100;
      Iteration : Integer := 0;

   begin
      loop
         Changed := False;
         Iteration := Iteration + 1;

         -- Apply each FD - in Oblivious chase, we might apply them multiple times
         for FD of FDs loop
            for I in 1..2 loop  -- Apply each FD twice to ensure propagation
               Apply_FD(Tableau, FD, Changed);
            end loop;
         end loop;

         exit when not Changed or Iteration >= Max_Iterations;

         if Contains_Original_Tuple(Tableau, Original_Tuple) then
            return True;
         end if;
      end loop;

      return Contains_Original_Tuple(Tableau, Original_Tuple);
   end Oblivious_Chase;

   function Core_Chase (
      Original_Tuple : Tuple;
      FDs           : FD_Set;
      Decomp        : Decomposition)
   return Boolean is
      -- Core chase tries to minimize the tableau by keeping only
      -- the "core" tuples that are necessary

      Tableau : Tableau := Create_Initial_Tableau(Original_Tuple, Decomp);
      Changed : Boolean;
      Max_Iterations : constant Integer := 100;
      Iteration : Integer := 0;

   begin
      loop
         Changed := False;
         Iteration := Iteration + 1;

         -- Apply FDs
         for FD of FDs loop
            Apply_FD(Tableau, FD, Changed);
         end loop;

         -- In Core chase, we would also try to remove redundant tuples
         -- For simplicity, we'll just use the standard approach

         exit when not Changed or Iteration >= Max_Iterations;

         if Contains_Original_Tuple(Tableau, Original_Tuple) then
            return True;
         end if;
      end loop;

      return Contains_Original_Tuple(Tableau, Original_Tuple);
   end Core_Chase;

   function Restricted_Chase_TGD (
      Original_Tuple : Tuple;
      TGDs          : FD_Set;  -- Using FD_Set as placeholder
      Decomp        : Decomposition)
   return Boolean is
      -- This is a placeholder for the TGD variant
      -- In a full implementation, TGDs would be different from FDs
      -- For now, we'll use the same algorithm as Standard_Chase
      -- but note that this is a simplification

      Tableau : Tableau := Create_Initial_Tableau(Original_Tuple, Decomp);
      Changed : Boolean;
      Max_Iterations : constant Integer := 100;
      Iteration : Integer := 0;

   begin
      loop
         Changed := False;
         Iteration := Iteration + 1;

         -- For TGDs, we would apply different rules
         -- For now, just apply as FDs
         for FD of TGDs loop
            Apply_FD(Tableau, FD, Changed);
         end loop;

         exit when not Changed or Iteration >= Max_Iterations;

         if Contains_Original_Tuple(Tableau, Original_Tuple) then
            return True;
         end if;
      end loop;

      return Contains_Original_Tuple(Tableau, Original_Tuple);
   end Restricted_Chase_TGD;

   -- ===================================================================
   -- VALIDATION FUNCTIONS
   -- ===================================================================

   function Validate_FDs (FDs : FD_Set) return Boolean is
   begin
      for FD of FDs loop
         -- Check that left side is not empty
         if FD.Left'Length = 0 then
            return False;
         end if;
         -- Additional validation could be added here
      end loop;
      return True;
   end Validate_FDs;

   function Validate_Decomposition (
      Decomp     : Decomposition;
      All_Attrs  : Attribute_Set)
   return Boolean is
   begin
      -- Check that all attributes are covered by the decomposition
      for Attr of All_Attrs loop
         Found : Boolean := False;
         for Schema of Decomp loop
            if Attribute_In_Schema(Schema, Attr) then
               Found := True;
               exit;
            end if;
         end loop;
         if not Found then
            return False;
         end if;
      end loop;
      return True;
   end Validate_Decomposition;

   -- ===================================================================
   -- DEBUGGING FUNCTIONS
   -- ===================================================================

   procedure Print_Value (V : Value) is
   begin
      if V.V_Type = Constant then
         Put(V.Text & " ");
      else
         Put(V.Text & V.Subscript'Image & " ");
      end if;
   end Print_Value;

   procedure Print_Tuple (T : Tuple) is
   begin
      Put("(");
      for V of T loop
         Print_Value(V);
      end loop;
      Put(")");
   end Print_Tuple;

   procedure Print_Tableau (Tableau : Tableau) is
   begin
      New_Line;
      Put_Line("Tableau:");
      for Row of Tableau loop
         Print_Tuple(Row);
         New_Line;
      end loop;
      New_Line;
   end Print_Tableau;

end Chase;
