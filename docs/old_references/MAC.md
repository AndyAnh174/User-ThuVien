Dưới đây là nội dung của file PDF bạn gửi, đã được chuyển đổi sang định dạng Markdown.

---

# DATABASE SECURITY: ACCESS CONTROL

**Lê Thị Minh Châu**
Faculty Of Information Technology
HCMC University Of Technology And Education

---

## Outline

*   Three Basic Concepts
*   DAC
*   MAC
*   RBAC
*   **Attribute Based Access Control**
*   Conclusion

---

## Three Basic Concepts

*   **Authentication:** a mechanism that determines whether a user is who he or she claims to be.
*   **Authorization:** the granting of a right or privilege, which enables a subject to legitimately have access to a system or a system's objects.
*   **Access Control:** a security mechanism (of a DBMS) for restricting access to a system's objects (the database) as a whole.

---

## Discretionary Access Control (DAC)

*   Widely used in modern operating systems
*   In most implementations it has the notion of owner of an object
*   The owner controls other users' accesses to the object
*   Allows access rights to be propagated to other subjects

---

## Discretionary Access Control (DAC)

*   **DAC:** granting access to the data on the basis of users' identity and of rules that specify the types of access each user is allowed for each object in the system.
*   **Identification & authentication:** 1st procedure
    *   **Identification:** a user claims who s/he is
    *   **Authentication:** establishing the validity of this claim
        *   something the user **knows** (e.g., a password, PIN)
        *   something the user **possesses** (e.g., an ATM card)
        *   something the user **is** (e.g., a voice pattern, a fingerprint)

---

## Discretionary Access Control (DAC)

*   The typical method of enforcing DAC in a database system is based on the granting and revoking privileges.
*   SQL standard supports DAC through the **GRANT** and **REVOKE** commands: The `GRANT` command gives privileges to users, and the `REVOKE` command takes away privileges.

---

## Problems with DAC in OS

*   DAC cannot protect against
    *   Trojan horse
    *   Malware
    *   Software bugs
    *   Malicious local users
*   It cannot control information flow

---

## DAC & Information Flow Controls

*   Inherent weakness of DAC: Unrestricted DAC allows information from an object which can be read by a subject to be written to any other object
    *   Bob is denied access to file A, so he asks cohort Alice to copy A to B that he can access
*   Suppose our users are trusted not to do this deliberately. It is still possible for Trojan Horses to copy information from one object to another.

---

## Trojan Horse Example

*[Figure: User Alice has read/write access to File A. User Bob has read/write access to File B. User Bob cannot read File A.]*

---

## Trojan Horse Example

*[Figure: Program X (with a Trojan Horse TH) is introduced. Alice has r/w to File A. Bob has r/w to File B, and Alice also has write access to File B.]*

---

## Trojan Horse Example

*[Figure: User Alice runs Pgm X. Pgm X reads File A, and the Trojan Horse writes the contents of File A to File B. User Bob can now read the contents of File A from File B.]*

---

## Trojan Horse Example (Database Context)

*[Figure: User X owns Table f1 (SELECT, INSERT...). User Y owns Table f2 (SELECT, INSERT...). User Y does NOT have SELECT on f1. User X has INSERT on f2. Program P (run by User X) reads f1 and inserts into f2. This demonstrates information flow from f1 to f2, bypassing Y's restriction on f1.]*

---

## Mandatory Access Control (MAC)

*   **Mandatory access control (MAC)** restricts the access of subjects to objects based on a system-wide policy
*   The system security policy (as set by the administrator) entirely determines the access rights granted
    *   denying users full control over the access to resources that they create.

---

## The Need for MAC

*   Host compromise by network-based attacks is the root cause of many serious security problems
    *   Worm, Botnet, DDoS, Phishing, Spamming
*   Why hosts can be easily compromised
    *   Programs contain exploitable bugs
    *   The discretionary access control mechanism in the operating systems was not designed by taking into account buggy software

---

## Mandatory Access Control (MAC)

*   MAC specifies the access that subjects have to objects based on subjects and objects classification
*   This type of security has also been referred to as **multilevel security**
*   Database systems that satisfy multilevel security properties are called **multilevel secure database management systems (MLS/DBMSs)**
*   Many of the MLS/DBMSs have been designed based on the **Bell and LaPadula (BLP) model**

---

## Multilevel Relation

A multilevel relation will appear to contain different data to subjects (users) with different security levels.

**EMPLOYEE Table Example:**

| Name    | Salary  | JobPerformance | TC |
| :------ | :------ | :------------- | :- |
| Smith U | 40000 C | Fair           | S  |
| Brown C | 80000 S | Good           | C  |

---

## A Characterization of the Difference between DAC and MAC

### Discretionary Access Control Models (DAC)
*   **Definition** [Bishop p.53] If an individual user can set an access control mechanism to allow or deny access to an object, that mechanism is a discretionary access control (DAC), also called an identity-based access control (IBAC).

### Mandatory Access Control Models (MAC)
*   **Definition** [Bishop p.53] When a system mechanism controls access to an object and an individual user cannot alter that access, the control is a mandatory access control (MAC) [, occasionally called a rule-based access control.]

---

## Bell and LaPadula (BLP) Model

**Elements of the model:**

*   **objects** - passive entities containing information to be protected
*   **subjects:** active entities requiring accesses to objects (users, processes)
*   **access modes:** types of operations performed by subjects on objects
    *   **read:** reading operation
    *   **append:** modification operation
    *   **write:** both reading and modification

---

## BLP Model

*   Subjects are assigned **clearance levels** and they can operate at a level up to and including their clearance levels
*   Objects are assigned **sensitivity levels**
*   The clearance levels as well as the sensitivity levels are called **access classes**

---

## BLP Model - Access Classes

*   An access class consists of two components:
    *   a **security level**
    *   a **category set**
*   The **security level** is an element from a totally ordered set - example:
    *   {Top Secret (TS), Secret (S), Confidential (C), Unclassified (U)}
    *   where TS > S > C > U
*   The **category set** is a set of elements, dependent from the application area in which data are to be used - example:
    *   {Army, Navy, Air Force, Nuclear}

---

## BLP Model - Access Classes

Access class `c_i = (L_i, SC_i)` **dominates** access class `c_k = (L_k, SC_k)`, denoted as `c_i >= c_k`, if both the following conditions hold:

*   `L_i >= L_k`
    *   The security level of `c_i` is greater or equal to the security level of `c_k`
*   `SC_i >= SC_k` (SC_i includes SC_k)
    *   The category set of `c_i` includes the category set of `c_k`

---

## BLP Model - Access Classes

*   If `L_i > L_k` and `SC_i >= SC_k`, we say that `c_i` **strictly dominates** `c_k`
*   `c_i` and `c_k` are said to be **incomparable** (denoted as `c_i < > c_k`) if neither `c_i >= c_k` nor `c_k >= c_i` holds

---

## BLP Model - Examples

**Access classes**
*   `c_1 = (TS, {Nuclear, Army})`
*   `c_2 = (TS, {Nuclear})`
*   `c_3 = (C, {Army})`
*   `c_1 >= c_2`
*   `c_1 > c_3` (TS > C and {Army} subset of {Nuclear, Army})
*   `c_2 < > c_3`

---

## Bell and LaPadula (BLP) Model - Axioms

*   The state of the system is described by the pair `(A, L)`, where:
    *   `A` is the **set of current accesses:** triples of the form `(s,o,m)` denoting that subject `s` is exercising access `m` on object `o` - example (Bob, `o_1`, read)
    *   `L` is the **level function:** it associates each element in the system with its access class
    *   Let `O` be the set of objects, `S` the set of subjects, and `C` the set of access classes
    *   `L: O U S -> C`

---

## Bell and LaPadula (BLP) Model - Axioms

### Simple security property (no-read-up)
A given state `(A, L)` satisfies the simple security property if for each element `a = (s,o,m) ∈ A` one of the following condition holds:

1.  `m = append`
2.  (`m = read` or `m = write`) and `L(s) >= L(o)`

*   **Example:** a subject with access class (C, {Army}) is **not allowed** to read objects with access classes (C, {Navy, Air Force}) or (U, {Air Force})

---

## Bell and LaPadula (BLP) Model - Axioms

*   The simple security property prevents subjects from reading data with access classes dominating or incomparable with respect with the subject access class
*   It therefore ensures that subjects have access only to information for which they have the necessary access class

---

## Bell and LaPadula (BLP) Model - Axioms

### Star (*) property (no-write-down)
A given state `(A, L)` satisfies the *-property if for each element `a = (s,o,m) ∈ A` one of the following condition holds:

1.  `m = read`
2.  `m = append` and `L(o) >= L(s)`
3.  `m = write` and `L(o) = L(s)`

*   **Example:** a subject with access class (C,{Army, Nuclear}) is **not allowed** to append data into objects with access class (U, {Army, Nuclear})

---

## Bell and LaPadula (BLP) Model - Axioms

*   The *-property has been defined to prevent information flow into objects with lower-level access classes or incomparable classes
*   For a system to be secure both properties must be verified by any system state

---

## Summary of BLP Model

*   Typical **security classes** are top secret (TS), secret (S), confidential (C), and unclassified (U): `TS >= S >= C >= U`
*   Two restrictions are enforced on data access based on the subject/object classifications:
    *   A subject `S` is not allowed read access to an object `O` unless `class(S) >= class(O)`. This is known as the **simple security property**.
    *   A subject `S` is not allowed to write an object `O` unless `class(S) <= class(O)`. This known as the **star property** (or * property).

---

## Multilevel Relation (User Views)

### SELECT * FROM EMPLOYEE (Full Table)

| Name    | Salary  | JobPerformance | TC |
| :------ | :------ | :------------- | :- |
| Smith U | 40000 C | Fair           | S  |
| Brown C | 80000 S | Good           | C  |

### A user with security level S

| Name    | Salary  | JobPerformance | TC |
| :------ | :------ | :------------- | :- |
| Smith U | 40000 C | Fair           | S  |
| Brown C | 80000 S | Good           | C  |

### A user with security level C

| Name    | Salary  | JobPerformance | TC |
| :------ | :------ | :------------- | :- |
| Smith U | 40000 C | null           | C  |
| Brown C | null    | Good           | C  |

### A user with security level U

| Name    | Salary | JobPerformance | TC |
| :------ | :----- | :------------- | :- |
| Smith U | null   | null           | U  |

---

## Multilevel Relation (Update Example)

### EMPLOYEE (security level C) - View

| Name    | Salary  | JobPerformance | TC |
| :------ | :------ | :------------- | :- |
| Smith U | 40000 C | null           | C  |
| Brown C | null    | Good           | C  |

*   A user with security level C tries to update the value of JobPerformance of Smith to 'Excellent':
    ```sql
    UPDATE EMPLOYEE
    SET JobPerformance = 'Excellent'
    -- WHERE Name = 'Smith' (implied from context)
    ```
*   **Resulting EMPLOYEE table (after update, assuming it was allowed based on BLP rules):**

| Name    | Salary  | JobPerformance | TC |
| :------ | :------ | :------------- | :- |
| Smith U | 40000 C | Excellent      | C  |
| Brown C | 80000 S | Good           | C  |

---

## Pros and Cons of MAC

### Pros:
*   Provide a high degree of protection – in a way of preventing any illegal flow of information.
*   Suitable for military types of applications.

### Cons:
*   Not easy to apply: require a strict classification of subjects and objects into security levels.
*   Applicable for very few environments.

---

## Role-Based Access Control – RBAC

*   RBAC emerged rapidly in the 1990s as a proven technology for managing and enforcing security in large-scale enterprise systems.
*   Its basic notion is that permissions are associated with roles, and users are assigned to appropriate roles.
*   Roles can be created using the `CREATE ROLE` and `DESTROY ROLE` commands. Similarly to DAC, the `GRANT` and `REVOKE` commands can then be used to assign and revoke privileges from roles.

---

## Role-Based Access Control – RBAC (Role Hierarchy)

*[Figure: Diagram showing Users (Surgeon, Radiologist, Physician, Patient) mapped to a Role Hierarchy (Surgeon, Radiologist, Physician, Patient) which then maps to Permissions (Operate, Perform X-Ray, Write Prescription, Read Prescription). Surgeon role has Operate permission. Radiologist role has Perform X-Ray. Physician role has Write Prescription and Read Prescription. Patient role has Read Prescription.]*

---

## Role-Based Access Control – RBAC (Comparison)

*[Figure: Two diagrams comparing access control models.]*
*   **Traditional Access Control:** User -> Access -> Object
*   **Role Based Access Control:** User -> Acquire -> Role -> Access -> Object

---

## Role-Based Access Control – RBAC (Systems Comparison)

### Non-role-based systems
*[Figure: Diagram showing Users (Alice, Bob, Carl, Dave, Eva) directly mapped to Permissions (DB2 Account, WebSphere Account, Windows Account, Linux Account) in a many-to-many fashion.]*

### Role-Based Access Control Systems (RBAC)
*[Figure: Diagram showing Users (Alice, Bob, Carl, Dave, Eva) mapped to Roles (DB Admin, Web Admin, Software Developer), and then Roles mapped to Permissions (DB2 Account, WebSphere Account, Windows Account, Linux Account). This shows a more structured, indirect mapping.]*

---

## Core RBAC

*[Figure: Diagram illustrating the Core RBAC model. Users are assigned to Roles (User-Role Assignment). Roles are assigned Permissions (Permission-Role Assignment). Sessions link Users to Roles.]*

---

## Pros and Cons of RBAC

### Pros:
*   Simple, efficient model.
*   Suitable for most of the applications in practice.
*   Simple to manage permissions, managing permissions on each group instead of on each user -> reduce the effort, time and risk of confusion.

### Cons:
*   Not suitable for some resources to be protected that is not known in advance.
*   Not suitable for applications where a user can have many roles in conflict.

---

## Conclusion

### DAC (Discretionary Access Control)
*[Figure: Diagram showing Individuals directly mapping to Resources (Server 1, Server 2, Server 3) based on an Application Access List (Name, Access: Tom Yes, John No, Cindy Yes).]*

### MAC (Mandatory Access Control)
*[Figure: Diagram showing Individuals mapping to Resources (Server 1 "Top Secret", Server 2 "Secret", Server 3 "Classified") based on predefined security classifications. Individuals can only access resources at or below their clearance level.]*

### RBAC (Role-Based Access Control)
*[Figure: Diagram showing Individuals mapping to Roles (Role 1, Role 2, Role 3), and then Roles mapping to Resources (Server 1, Server 2, Server 3). This illustrates the indirect access via roles.]*

---

## Q&A

*[Image: Magnifying glass over the words "QUESTIONS And Answers"]*