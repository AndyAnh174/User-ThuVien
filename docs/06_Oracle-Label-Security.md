Chào bạn, đây là nội dung file PDF **"Bài thực hành số 6: ORACLE LABEL SECURITY (1)"** đã được chuyển đổi sang định dạng Markdown. Mình đã trình bày lại các đoạn mã SQL, bảng biểu và các bước cài đặt để bạn dễ theo dõi.

---

# Bài thực hành số 6: ORACLE LABEL SECURITY (1)

### ❖ Tóm tắt nội dung:
*   Mô hình DAC và MAC
*   DAC và MAC trong Oracle
*   Giới thiệu Oracle Label Security
*   Hướng dẫn cài đặt Oracle Label Security
*   Chính sách trong Oracle Label Security
*   Các thành phần của nhãn trong Oracle Label Security
*   Nhãn dữ liệu (data label)

---

## I. Giới thiệu

### A. Lý thuyết

#### 1. Mô hình DAC và MAC
*   Có 2 mô hình tiêu biểu dùng để quản lý việc truy xuất dữ liệu một cách đúng đắn và bảo đảm an toàn cho dữ liệu là **DAC (Discretionary Access Control)** và **MAC (Mandatory Access Control)**.
*   **DAC:** quản lý việc truy xuất dữ liệu bằng cách quản lý việc cấp phát các quyền truy xuất cho những người dùng thích hợp tùy theo yêu cầu của các chính sách bảo mật.
*   **MAC:** quản lý việc truy xuất dựa trên mức độ nhạy cảm của dữ liệu và mức độ tin cậy của người dùng truy xuất CSDL. Bằng cách phân lớp và gán nhãn cho dữ liệu và người dùng, đồng thời áp dụng quy tắc **“no read up - no write down”**, mô hình MAC giúp ta tránh được việc rò rỉ dữ liệu có mức độ nhạy cảm cao ra cho những người dùng có độ tin cậy thấp.

#### 2. MAC và DAC trong Oracle
*   **DAC:** Trong Oracle Database, các nhà quản trị có thể áp dụng mô hình DAC thông qua việc quản lý các truy xuất theo quyền đối tượng và quyền hệ thống (bài Lab 2 – Quyền và Role).
*   **MAC:** Oracle hiện thực mô hình MAC trên lý thuyết thành sản phẩm **Oracle Label Security (OLS)**. Tuy nhiên, do mô hình MAC lý thuyết tuân theo nguyên tắc *“no read up - no write down”* nên chỉ bảo đảm tính bí mật mà không có tính toàn vẹn. Để cung cấp một mô hình bảo vệ tốt hơn cho CSDL của khách hàng, OLS của Oracle đã cải tiến mô hình MAC lý thuyết bằng cách thay đổi nguyên tắc trên thành **“no read up - no write up - limited write down”**. Nhờ vậy, tính bảo mật và tính toàn vẹn của dữ liệu được bảo đảm.
    *   Mặt khác, khác với mô hình lý thuyết, OLS không bắt buộc áp dụng MAC cho toàn bộ CSDL. Người quản trị có thể chỉ định ra những table hoặc schema nào sẽ được áp dụng OLS.
*   **Mối tương quan giữa DAC và MAC:**
    Khi người dùng nhập vào 1 câu truy vấn SQL:
    1.  Đầu tiên Oracle sẽ kiểm tra **DAC** để bảo đảm rằng user đó có quyền truy vấn trên bảng được nhắc đến.
    2.  Kế tiếp Oracle sẽ kiểm tra xem có chính sách **VPD (Virtual Private Database)** nào được áp dụng cho bảng đó không. Nếu có, chuỗi điều kiện của chính sách VPD sẽ được nối thêm vào câu truy vấn gốc.
    3.  Cuối cùng, Oracle sẽ kiểm tra các **nhãn OLS** trên mỗi hàng dữ liệu để xác định những hàng nào mà người dùng có thể truy xuất.

#### 3. Giới thiệu Oracle Label Security
*   **Oracle Label Security (OLS)** là một sản phẩm được hiện thực dựa trên nền tảng công nghệ Virtual Private Database (VPD), cho phép các nhà quản trị điều khiển truy xuất dữ liệu ở mức hàng (row-level) một cách tiện lợi và dễ dàng hơn. Nó điều khiển việc truy xuất nội dung của các dòng dữ liệu bằng cách **so sánh nhãn của hàng dữ liệu với nhãn và quyền của user**.
*   Có 6 package được hiện thực sẵn cho OLS:
    1.  **SA_SYSDBA:** tạo, thay đổi, xóa các chính sách.
    2.  **SA_COMPONENTS:** định nghĩa và quản lý các thành phần của nhãn.
    3.  **SA_LABEL_ADMIN:** thực hiện các thao tác quản trị chính sách, nhãn.
    4.  **SA_POLICY_ADMIN:** áp dụng chính sách cho bảng và schema.
    5.  **SA_USER_ADMIN:** quản lý việc cấp phát quyền truy xuất và quy định mức độ tin cậy cho các user liên quan.
    6.  **SA_AUDIT_ADMIN:** thiết lập các tùy chọn cho các tác vụ quản trị việc audit.

#### 4. Năm bước hiện thực OLS
Quy trình cơ bản để hiện thực một chính sách OLS gồm 5 bước:
*   **B1:** Tạo chính sách OLS.
*   **B2:** Định nghĩa các thành phần mà một nhãn thuộc chính sách trên có thể có.
*   **B3:** Tạo các nhãn dữ liệu thật sự mà bạn muốn dùng.
*   **B4:** Gán chính sách trên cho các bảng hoặc schema mà bạn muốn bảo vệ.
*   **B5:** Gán các giới hạn quyền, các nhãn người dùng hoặc các quyền truy xuất đặc biệt cho những người dùng liên quan.

---

### B. Thực hành

#### 1. Cài đặt OLS
*   Cài đặt mặc định của Oracle không bao gồm tính năng OLS. Bạn phải có quyền admin để cài đặt thêm.
*   Trong ví dụ này, SID của CSDL là **ORCL**.
*   **Các bước cài đặt:**
    1.  Tắt dịch vụ `OracleService<SID>` (ví dụ `OracleServiceORCL`) trong *Services*.
    2.  Chạy file `setup.exe` trong bộ cài Oracle Database Enterprise Edition.
    3.  Chọn **Advanced Installation** -> **Next**.
    4.  Chọn **Custom** -> **Next**.
    5.  Nhập thông tin đường dẫn (giữ nguyên mặc định nếu không thay đổi) -> **Next**.
    6.  Trong cửa sổ *Available Product Components*, đánh dấu vào ô **Oracle Label Security**.
    7.  Tiếp tục làm theo hướng dẫn để hoàn tất cài đặt.

#### 2. Cấu hình để sử dụng OLS
1.  Chạy **Database Configuration Assistant** (Start -> Programs -> Oracle... -> Configuration and Migration Tools).
2.  Chọn **Configure Database Options** -> **Next**.
3.  Chọn CSDL muốn cài đặt (ví dụ ORCL) -> **Next**.
4.  Chọn **Oracle Label Security** -> **Next**.
5.  Để mặc định các thông số tiếp theo và chọn **Finish**.
6.  Restart Database khi được yêu cầu.

#### 3. Kích hoạt tài khoản LBACSYS
Để tạo ra các chính sách, ta phải đăng nhập bằng tài khoản **LBACSYS**. Mặc định tài khoản này bị khóa.
```sql
ALTER USER lbacsys IDENTIFIED BY lbacsys ACCOUNT UNLOCK;
```

#### 4. Chuẩn bị dữ liệu
Ta sẽ sử dụng schema **HR** có sẵn. Tạo thêm các user quản trị và nhân viên:

*   **HR:** Chủ sở hữu dữ liệu.
*   **HR_SEC:** Quản lý user nào được truy xuất dữ liệu trong HR.
*   **SEC_ADMIN:** Quản lý chính sách bảo mật cho HR.

```sql
-- Unlock HR
ALTER USER hr IDENTIFIED BY hr ACCOUNT UNLOCK;

-- Tạo user HR_SEC
GRANT connect, create user, drop user, create role, drop any role
TO HR_SEC IDENTIFIED BY HR_SEC;

-- Tạo user SEC_ADMIN
GRANT connect TO SEC_ADMIN IDENTIFIED BY SEC_ADMIN;

-- Tạo role và user nhân viên
CREATE ROLE emp_role;
GRANT connect TO emp_role;

-- Steven King (Tổng Giám đốc)
CREATE USER sking IDENTIFIED BY sking;
GRANT emp_role TO sking;

-- Neena Kochhar (Giám đốc điều hành)
CREATE USER nkochhar IDENTIFIED BY nkochhar;
GRANT emp_role TO nkochhar;

-- Karen Partner (Trưởng phòng Sales)
CREATE USER kpartner IDENTIFIED BY kpartner;
GRANT emp_role TO kpartner;

-- Louise Doran (Nhân viên thuộc phòng Sales)
CREATE USER ldoran IDENTIFIED BY ldoran;
GRANT emp_role TO ldoran;

-- Cấp quyền xem dữ liệu cho nhân viên (HR thực hiện)
CONN hr/hr;
GRANT select ON hr.locations TO emp_role;
```

---

## II. Chính sách trong Oracle Label Security

### A. Lý thuyết
*   **Chính sách (policy):** là danh sách tập hợp thông tin về các nhãn dữ liệu, nhãn người dùng, quy định quyền truy xuất, điều kiện áp dụng.
*   Với mỗi chính sách được áp dụng trên một bảng, một cột dùng để lưu thông tin nhãn dữ liệu (**data label**) sẽ được thêm vào bảng. Tên cột này phải là duy nhất trong toàn bộ các chính sách OLS của CSDL.
*   Các cột chứa thông tin chính sách có kiểu `NUMBER`. Giá trị lưu trong cột này là **tag** (số đại diện cho nhãn).
*   Sử dụng package **SA_SYSDBA** để quản lý chính sách (`CREATE_POLICY`, `ALTER_POLICY`, `DISABLE_POLICY`, `ENABLE_POLICY`, `DROP_POLICY`).

### B. Thực hành
*   Tạo chính sách mới tên là `ACCESS_LOCATIONS`, tên cột chứa nhãn là `OLS_COLUMN`.

```sql
CONN lbacsys/lbacsys;
BEGIN
  SA_SYSDBA.CREATE_POLICY (
    policy_name => 'ACCESS_LOCATIONS',
    column_name => 'OLS_COLUMN');
END;
/
```

*   Khi chính sách được tạo, Oracle tự động tạo ra role quản trị: `<tên_chính_sách>_DBA`. Ví dụ: `ACCESS_LOCATIONS_DBA`.
*   Cấp quyền quản trị chính sách cho **SEC_ADMIN** và **HR_SEC**:

```sql
CONN lbacsys/lbacsys;
-- Cấp role quản trị chính sách cho SEC_ADMIN
GRANT access_locations_dba TO sec_admin;

-- Cấp quyền thực thi các package cho SEC_ADMIN
GRANT execute ON sa_components TO sec_admin;
GRANT execute ON sa_label_admin TO sec_admin;
GRANT execute ON sa_policy_admin TO sec_admin;

-- Cấp role quản trị chính sách cho HR_SEC
GRANT access_locations_dba TO hr_sec;
-- Cấp quyền thực thi package gán label cho user
GRANT execute ON sa_user_admin TO hr_sec;
```

*   **Lưu ý:** User muốn quản lý chính sách nào thì phải có **role quản trị của chính sách đó**. Chỉ có quyền execute trên package là chưa đủ.

*   *Ví dụ minh họa việc thất bại khi không có role:*
```sql
-- Tạo policy mới nhưng không gán role cho sec_admin
CONN lbacsys/lbacsys;
BEGIN
  sa_sysdba.create_policy (policy_name => 'Different_Policy');
END;
/

-- Thử quản lý policy mới (sẽ thất bại)
CONN sec_admin/secadmin;
BEGIN
  sa_components.create_level (
    policy_name => 'Different_Policy',
    long_name => 'foo',
    short_name => 'bar',
    level_num => 9);
END;
/
-- ERROR: ORA-12407: unauthorized operation for policy Different_Policy

-- Xóa policy thử nghiệm
CONN lbacsys/lbacsys;
BEGIN
  sa_sysdba.drop_policy (policy_name => 'Different_Policy', drop_column => true);
END;
/
```

---

## III. Các thành phần của nhãn dữ liệu

### A. Lý thuyết

#### 1. Nhãn dữ liệu (data label)
*   Dùng để phân lớp dữ liệu theo mức độ nhạy cảm.
*   Gồm 3 thành phần: **Level, Compartment, Group**.

#### 2. Các thành phần
**a. Level (Cấp độ):**
*   Biểu thị độ nhạy cảm (Top Secret, Secret, Confidential, Public).
*   Mỗi nhãn có đúng **1 level**.
*   **Dạng số (numeric form):** 0-9999. Giá trị càng cao, độ nhạy cảm càng cao.
*   **Dạng chuỗi:** Tên đầy đủ (long form) và tên rút gọn (short form).

| Dạng số | Dạng chuỗi dài | Dạng chuỗi ngắn |
| :--- | :--- | :--- |
| 40 | HIGHLY_SENSITIVE | HS |
| 30 | SENSITIVE | S |
| 20 | CONFIDENTIAL | C |
| 10 | PUBLIC | P |

**b. Compartment (Phạm vi/Lĩnh vực):**
*   Phân loại theo lĩnh vực, dự án (Financial, Chemical...). Không mang tính phân cấp độ nhạy cảm.
*   Mỗi nhãn có thể có 0, 1 hoặc nhiều compartment.

| Dạng số | Dạng chuỗi dài | Dạng chuỗi ngắn |
| :--- | :--- | :--- |
| 85 | FINANCIAL | FINCL |
| 65 | CHEMICAL | CHEM |
| 45 | OPERATIONAL | OP |

**c. Group (Nhóm tổ chức):**
*   Xác định tổ chức sở hữu dữ liệu. Có cấu trúc cây phân cấp (Cha - Con).
*   Mỗi nhãn có thể có 0, 1 hoặc nhiều group.

| Dạng số | Dạng chuỗi dài | Dạng chuỗi ngắn | Group cha |
| :--- | :--- | :--- | :--- |
| 1000 | WESTERN_REGION | WR | |
| 1100 | WR_SALES | WR_SAL | WR |

### B. Thực hành
Sử dụng package **SA_COMPONENTS** để tạo các thành phần cho chính sách `ACCESS_LOCATIONS`.

#### 1. Tạo Level
```sql
CONN sec_admin/secadmin;

-- Tạo level PUBLIC (1000)
BEGIN
  sa_components.create_level (
    policy_name => 'ACCESS_LOCATIONS',
    long_name => 'PUBLIC',
    short_name => 'PUB',
    level_num => 1000);
END;
/

-- Tạo level CONFIDENTIAL (2000)
EXECUTE sa_components.create_level ('ACCESS_LOCATIONS',2000,'CONF','CONFIDENTIAL');

-- Tạo level SENSITIVE (3000)
EXECUTE sa_components.create_level ('ACCESS_LOCATIONS',3000,'SENS','SENSITIVE');
```

*   **Thay đổi Level:** Dùng `ALTER_LEVEL`. Có thể đổi tên nhưng **không thể đổi số đại diện**.
*   **Xóa Level:** Dùng `DROP_LEVEL`. Không thể xóa nếu đang được sử dụng.

#### 2. Tạo Compartment
```sql
CONN sec_admin/secadmin;

-- Tạo compartment SALES_MARKETING (2000)
BEGIN
  sa_components.create_compartment (
    policy_name => 'ACCESS_LOCATIONS',
    long_name => 'SALES_MARKETING',
    short_name => 'SM',
    comp_num => 2000);
END;
/

-- Tạo compartment FINANCE (3000)
EXECUTE sa_components.create_compartment ('ACCESS_LOCATIONS',3000,'FIN','FINANCE');

-- Tạo compartment HUMAN RESOURCES (1000)
EXECUTE sa_components.create_compartment ('ACCESS_LOCATIONS',1000,'HR','HUMAN RESOURCES');
```

#### 3. Tạo Group
Tạo group `CORPORATE` (cha) và các chi nhánh con (US, UK, CA).

```sql
CONN sec_admin/secadmin;

-- Tạo group cha CORPORATE
BEGIN
  sa_components.create_group (
    policy_name => 'ACCESS_LOCATIONS',
    long_name => 'CORPORATE',
    short_name => 'CORP',
    group_num => 10,
    parent_name => NULL);
END;
/

-- Tạo các group con
EXECUTE sa_components.create_group ('ACCESS_LOCATIONS',30,'US','UNITED STATES','CORP');
EXECUTE sa_components.create_group ('ACCESS_LOCATIONS',50,'UK','UNITED KINGDOM','CORP');
EXECUTE sa_components.create_group ('ACCESS_LOCATIONS',70,'CA','CANADA','CORP');
```

---

## IV. Chi tiết về nhãn dữ liệu

### A. Lý thuyết
*   **Cú pháp:** `LEVEL:COMPARTMENT1,...,COMPARTMENTn:GROUP1,...,GROUPn`
*   Ví dụ: `SENSITIVE:FINANCIAL,CHEMICAL:EASTERN_REGION`
*   **Label Tag:** Khi một nhãn dữ liệu mới được tạo, Oracle tự động tạo (hoặc người dùng chỉ định) một con số đại diện gọi là **label tag**.
    *   Mỗi label tag là duy nhất trong toàn bộ CSDL.
    *   Đây là giá trị thực sự được lưu vào cột chính sách trong bảng dữ liệu.

### B. Thực hành
Tạo các nhãn (Label) từ các thành phần đã tạo ở phần III bằng `SA_LABEL_ADMIN.CREATE_LABEL`.

*   **Quy ước đặt label tag trong bài lab:**
    *   Chữ số đầu: Level (1=PUB, 2=CONF, 3=SENS).
    *   2 chữ số tiếp: Compartment (00=không có).
    *   2 chữ số cuối: Group (00=không có).

```sql
CONN sec_admin/secadmin;

-- Tạo nhãn PUB (Tag 10000)
BEGIN
  sa_label_admin.create_label (
    policy_name => 'ACCESS_LOCATIONS',
    label_tag => 10000,
    label_value => 'PUB');
END;
/

-- Tạo nhãn CONF (Tag 20000)
EXECUTE sa_label_admin.create_label ('ACCESS_LOCATIONS',20000,'CONF');

-- Tạo các nhãn phức hợp
EXECUTE sa_label_admin.create_label ('ACCESS_LOCATIONS',20010,'CONF::US');
EXECUTE sa_label_admin.create_label ('ACCESS_LOCATIONS',20020,'CONF::UK');
EXECUTE sa_label_admin.create_label ('ACCESS_LOCATIONS',20030,'CONF::CA');

EXECUTE sa_label_admin.create_label ('ACCESS_LOCATIONS',21020,'CONF:HR:UK');
EXECUTE sa_label_admin.create_label ('ACCESS_LOCATIONS',22040,'CONF:SM:UK,CA');

EXECUTE sa_label_admin.create_label ('ACCESS_LOCATIONS',34000,'SENS:SM,FIN');
EXECUTE sa_label_admin.create_label ('ACCESS_LOCATIONS',39090,'SENS:HR,SM,FIN:CORP');
```

*   **Thay đổi nhãn:** `ALTER_LABEL`. Có thể thay đổi giá trị chuỗi của nhãn nhưng **không thể thay đổi label tag**.
*   **Xóa nhãn:** `DROP_LABEL`.

---

## V. Bài tập

1.  Tạo user `ols_test` và cấp quyền để user này truy cập vào hệ thống được. Cấp quyền thực thi trên các gói thủ tục cần thiết để user này quản lý được một chính sách.
2.  Tạo chính sách `region_policy` với tên cột chính sách là `region_label`. Thực hiện lệnh cần thiết để `ols_test` trở thành người quản lý chính sách này.
3.  Disable thủ tục đã tạo ở câu 2. Sau đó enable nó lại.
4.  Tạo các thành phần nhãn cho chính sách `region_policy`:
    *   **Level:** level 1, level 2, level 3
    *   **Compartment:** MANAGEMENT, EMPLOYEE
    *   **Group:** REGION NORTH, REGION SOUTH, REGION EAST, REGION WEST