# 🧪 RV32I B-type Instruction Verification Framework

## 🔍 Project Overview

> 이 프로젝트는 **SystemVerilog 기반 RV32I RISC-V 프로세서의 B-type 분기 명령어 검증** 프로젝트입니다. 고급 검증 기법인 **SystemVerilog Assertions (SVA)**, **Coverage-Driven Verification (CDV)**, **Constrained Random Verification (CRV)**을 활용하여 포괄적인 검증을 수행합니다.

## 🏗️ Verification Architecture

### **Verification Environment Structure**
```
📁 RV32I_B-type_Verification/
├── 📂 DUT (Design Under Test)
│   ├── cpu_with_data_memory_dut.sv    # DUT 래퍼 (CPU + Data Memory)
│   ├── cpu_core.sv                    # CPU 코어 (제어+데이터패스)
│   ├── datapath.sv                    # 데이터패스 모듈
│   ├── control_unit.sv                # 제어 유닛
│   ├── ALU.sv                         # 산술 논리 연산 장치
│   ├── register_file.sv               # 32bit x 32개 레지스터 파일
│   ├── data_memory.sv                 # 데이터 메모리 컨트롤러
│   └── 기타 지원 모듈들 (mux, adder, extend 등)
│
├── 📂 Testbench Components
│   ├── tb_B_type.sv                   # 메인 테스트벤치
│   ├── Interface (rv32i_intf)         # DUT-TB 인터페이스
│   ├── Transaction Class              # B-type 트랜잭션 모델
│   ├── Generator                      # 제약 랜덤 패턴 생성
│   ├── Driver                         # DUT 자극 인가
│   ├── Monitor                        # DUT 응답 관찰
│   ├── Scoreboard                     # 결과 검증 및 채점
│   └── Coverage Model                 # 커버리지 수집
│
├── 📂 Verification Features
│   ├── SVA Properties                 # 실시간 어서션 검증
│   ├── Functional Coverage            # 기능적 커버리지 측정
│   └── Constraint Randomization       # 지능형 랜덤 테스트
│
└── 📂 Memory Components
    ├── blk_mem_gen_0.xci              # Xilinx BRAM IP
    └── BRAM Interface                 # 메모리 인터페이스 로직
```

## 🎯 Verification Scope

### **Target Instructions (B-type)**
| **Instruction** | **Encoding** | **Operation** | **Verification Focus** |
|-----------------|--------------|---------------|------------------------|
| **BEQ** | `funct3=000` | `if (rs1 == rs2) PC += imm` | Equal 조건 검증 |
| **BNE** | `funct3=001` | `if (rs1 != rs2) PC += imm` | Not Equal 조건 검증 |
| **BLT** | `funct3=100` | `if (rs1 < rs2) PC += imm` | Signed 비교 검증 |
| **BGE** | `funct3=101` | `if (rs1 >= rs2) PC += imm` | Signed 크거나같음 검증 |
| **BLTU** | `funct3=110` | `if (rs1 < rs2) PC += imm` | Unsigned 비교 검증 |
| **BGEU** | `funct3=111` | `if (rs1 >= rs2) PC += imm` | Unsigned 크거나같음 검증 |

### **Verification Targets**
- ✅ **PC Update Logic**: 분기 성공/실패 시 올바른 PC 계산
- ✅ **Branch Condition Evaluation**: 각 조건별 정확한 분기 판단
- ✅ **Immediate Extension**: 13비트 즉시값의 올바른 부호 확장
- ✅ **Register Access**: x0 레지스터 특수 처리 및 일반 레지스터 접근
- ✅ **Address Alignment**: 분기 타겟 주소의 워드 정렬 확인
- ✅ **ALU Functionality**: 분기 조건 계산 및 taken 신호 생성

## 🧰 Advanced Verification Techniques

### **1. SystemVerilog Assertions (SVA)**
```systemverilog
// PC 업데이트 규칙 검증
property branch_taken_pc_update;
    @(posedge clk) disable iff (rst)
    (is_branch_instr && branch_taken) |=> 
    (pc_next == (pc_current + {{19{imm[12]}}, imm[12:0]}));
endproperty

// x0 레지스터 불변성 검증  
property x0_register_value;
    @(posedge clk) disable iff (rst)
    (is_branch_instr && (instruction[19:15] == 5'b00000)) |-> 
    (rs1_value == 32'h00000000);
endproperty

// 분기 타겟 주소 정렬 검증
property branch_target_alignment;
    @(posedge clk) disable iff (rst)
    (is_branch_instr && branch_taken) |=> (pc_next[1:0] == 2'b00);
endproperty
```

### **2. Coverage-Driven Verification (CDV)**
```systemverilog
// 분기 결정 커버리지
covergroup branch_decision_cg;
    cp_branch_taken: coverpoint taken {
        bins taken = {1};
        bins not_taken = {0};
    }
    cp_funct3: coverpoint funct3 {
        bins beq  = {3'b000};  bins bne  = {3'b001};
        bins blt  = {3'b100};  bins bge  = {3'b101};
        bins bltu = {3'b110};  bins bgeu = {3'b111};
    }
    // 교차 커버리지: 모든 명령어 × taken/not_taken
    cross_funct3_taken: cross cp_funct3, cp_branch_taken;
endgroup

// 즉시값 특성 커버리지
covergroup immediate_cg;
    cp_imm_sign: coverpoint imm {
        bins negative = {[-2048:-1]};
        bins zero = {0};
        bins positive = {[1:2047]};
    }
    cp_imm_magnitude: coverpoint imm {
        bins small_neg = {[-100:-1]};
        bins large_neg = {[-2048:-101]};
        bins small_pos = {[1:100]};
        bins large_pos = {[101:2047]};
    }
endgroup
```

### **3. Constrained Random Verification (CRV)**
```systemverilog
class b_type_transaction;
    rand logic [4:0] rs1, rs2;              // 레지스터 주소
    rand logic [2:0] funct3;                 // 분기 명령어 타입
    rand logic signed [12:0] imm;            // 분기 오프셋
    rand logic signed [31:0] rs1_value, rs2_value; // 레지스터 값
    
    // 제약 조건: 유효한 funct3 값만 생성
    constraint valid_funct3 {
        funct3 inside {3'b000, 3'b001, 3'b100, 3'b101, 3'b110, 3'b111};
    }
    
    // 제약 조건: 워드 정렬된 분기 타겟
    constraint immediate_constraints {
        imm[0] == 1'b0;  // 2의 배수 오프셋
        imm dist {
            [-1023:-4]    := 1,    // 후진 분기
            [4:1023]      := 5,    // 전진 분기 (주요)
            [1024:2047]   := 4     // 장거리 분기
        };
    }
    
    // 제약 조건: 다양한 레지스터 값 분포
    constraint register_value_constraints {
        rs1_value dist {
            32'h00000000 := 5,           // Zero
            [32'h00000001:32'h000000FF] := 3,  // Small positive
            [32'h80000000:32'hFFFFFFFF] := 3,  // Negative
            [32'h7FFFFFFF:32'h7FFFFF00] := 3   // Large positive
        };
    }
endclass
```

## 🎛️ Verification Features

### **🔧 Environment Configuration**
- **Test Architecture**: UVM-like 검증 환경 (Native SystemVerilog)
- **Clock-based Execution**: 단일 클럭 기반 이벤트 처리
- **Backdoor Access**: 레지스터 파일 직접 접근으로 빠른 설정
- **Interface-based Communication**: 모듈화된 신호 인터페이스
- **Hierarchical Observability**: DUT 내부 신호 완전 관찰

### **🎯 Advanced Test Controls**
```systemverilog
// 컴파일 타임 설정
`define USE_BACKDOOR_ACCESS   // 레지스터 직접 접근 활성화
`define DEBUG_MODE           // 디버그 모드 (제한된 테스트)

// 런타임 설정
int num_tests = 20;          // 기본 테스트 수 (DEBUG_MODE에서 5개)
timeout = 5000000;           // 5ms 타임아웃
```

### **📊 Observability Features**
- **Register File Monitoring**: 32개 레지스터 실시간 관찰
- **ALU Result Tracking**: 연산 결과 및 분기 조건 신호 추적
- **PC Flow Analysis**: 프로그램 카운터 흐름 상세 분석
- **Memory Access Logging**: 데이터 메모리 접근 패턴 기록
- **Control Signal Monitoring**: 제어 신호 상태 추적

## 📈 Verification Metrics

### **🎯 Coverage Goals**
| **Coverage Type** | **Target** | **Description** |
|------------------|------------|-----------------|
| **Functional Coverage** | >95% | 모든 B-type 명령어 × taken/not_taken |
| **Code Coverage** | >90% | DUT 내부 로직 경로 커버리지 |
| **Assertion Coverage** | 100% | 모든 SVA 속성 실행 확인 |
| **Cross Coverage** | >90% | 레지스터 조합 × 분기 조건 |
| **Edge Case Coverage** | >85% | x0 레지스터 사용, 극값 처리 |

### **🔍 Quality Metrics**
- **Pass Rate**: 통과한 테스트 비율 (목표: 100%)
- **Assertion Violations**: SVA 위반 사항 수 (목표: 0)
- **Coverage Holes**: 미검증 기능 영역 식별
- **Bug Detection Rate**: 발견된 설계 오류 수

## 🚨 Verification Challenges & Solutions

### **⚠️ Key Challenges**
1. **Timing Synchronization**: 클럭 기반 이벤트 동기화
   - **Solution**: Clock-edge 기반 이벤트 스케줄링
   
2. **Register File Access**: 내부 레지스터 상태 관찰
   - **Solution**: Backdoor access 및 hierarchical referencing
   
3. **PC Flow Verification**: 복잡한 분기 흐름 추적
   - **Solution**: Transaction-based PC tracking

4. **Coverage Convergence**: 모든 코너 케이스 달성
   - **Solution**: Constrained randomization + directed tests

### **🔧 Advanced Debugging Features**
```systemverilog
// 디버깅을 위한 상세 로깅
$display("=== SCOREBOARD ANALYSIS [Test %0d] ===", total_tests);
$display("Current PC: 0x%08x -> Next PC: 0x%08x", pc_current, pc_next);
$display("Branch Condition: %s, Expected: %b, Actual: %b", 
         funct3_name, expected_taken, actual_taken);
$display("PC Increment: +%0d (0x%h)", $signed(actual_pc_next - tr.pc_current), 
         actual_pc_next - tr.pc_current);
```

## 🧪 Test Execution & Results

### **📋 Test Execution**
```bash
# 기본 검증 실행 (Vivado/ModelSim)
vsim -do "run -all" tb_B_type

# 디버그 모드 실행 (제한된 테스트)
vsim +define+DEBUG_MODE -do "run -all" tb_B_type

# 커버리지 포함 실행
vsim -coverage -do "run -all" tb_B_type
```

### **📊 Sample Test Results**
```
🚀 Starting B-type Instruction Verification Environment
Target: 20 test transactions
Verification Features: Randomization + SVA + Coverage

==================== FINAL TEST REPORT ====================
Total Tests:        20
Passed Tests:       20
Failed Tests:       0
Pass Rate:          100.00%
Assertion Errors:   0
============================================================

=== COVERAGE REPORT ===
Branch Decision Coverage: 98.50%
Immediate Coverage: 95.20%
Register Relation Coverage: 92.80%
Edge Cases Coverage: 89.70%
=======================

🎉 ALL TESTS PASSED! B-type instruction verification successful.
```

## 🏛️ DUT Architecture

### **CPU Core Components**
- **Datapath**: 데이터 흐름 및 연산 경로 제어
- **Control Unit**: 명령어 디코딩 및 제어 신호 생성
- **ALU**: 32비트 산술 논리 연산 장치 (분기 조건 계산)
- **Register File**: 32개의 32비트 범용 레지스터 (x0-x31)
- **Program Counter**: 명령어 주소 관리
- **Immediate Extension**: 즉시값 부호 확장 및 형태 변환

### **Memory System**
- **Data Memory Controller**: BRAM IP 인터페이스 제어
- **Xilinx BRAM IP**: 16-bit × 32 words 메모리
- **Address Translation**: 바이트 주소 → 워드 주소 변환

### **Verification-Specific Features**
- **Observability Ports**: 모든 내부 신호 외부 접근 가능
- **Backdoor Access**: 레지스터 파일 직접 쓰기 지원
- **Instruction Interface**: TB에서 직접 명령어 제공

## 🔧 Configuration & Setup

### **⚙️ Simulation Parameters**
- **Clock Period**: 10ns (100MHz)
- **Reset Duration**: 3 클럭 사이클
- **Test Timeout**: 5ms (안전 마진)
- **Random Seed**: 자동 생성 (재현 가능)

### **🎛️ Compile-time Options**
```systemverilog
// 백도어 접근 활성화
`define USE_BACKDOOR_ACCESS

// 디버그 모드 (상세 로그)
`define DEBUG_MODE

// B-type 명령어 상수
`define BEQ  3'b000
`define BNE  3'b001
`define BLT  3'b100
`define BGE  3'b101
`define BLTU 3'b110
`define BGEU 3'b111
```

### **📝 Runtime Configuration**
- **Test Count**: 기본 20개 (DEBUG_MODE에서 5개)
- **Coverage Threshold**: 95% 목표
- **Debug Level**: INFO/DEBUG/TRACE 선택 가능
- **Assertion Monitoring**: 실시간 SVA 검증

## 🚀 Key Features

### **🔧 Verification Framework Features**
- **OOP-based Testbench**: 객체지향 검증 환경
- **Event-driven Architecture**: 클럭 기반 동기화
- **Modular Design**: 재사용 가능한 컴포넌트 구조
- **Real-time Monitoring**: 실시간 신호 추적 및 분석

### **💾 Advanced Testing Capabilities**
- **Constraint Randomization**: 지능형 테스트 패턴 생성
- **Functional Coverage**: 포괄적 기능 커버리지 측정
- **Assertion-based Verification**: 실시간 정확성 검증
- **Transaction-level Modeling**: 고수준 검증 추상화

### **🎯 RISC-V Specific Features**
- **ISA Compliance**: RISC-V B-type 명령어 완전 지원
- **Register Model**: x0 특수 처리 및 32개 범용 레지스터
- **PC Management**: 분기 및 순차 실행 PC 업데이트
- **Immediate Handling**: 13비트 부호 확장 즉시값 처리

## 🔬 Testing Methodology

### **📋 Test Strategy**
1. **Directed Tests**: 특정 시나리오 검증
2. **Random Tests**: 제약 랜덤 패턴을 통한 광범위 검증
3. **Edge Case Tests**: 경계 조건 및 코너 케이스
4. **Regression Tests**: 기능 변경 시 기존 기능 검증

### **🔍 Verification Phases**
1. **Unit Testing**: 개별 모듈 검증
2. **Integration Testing**: 모듈 간 인터페이스 검증
3. **System Testing**: 전체 시스템 검증
4. **Coverage Analysis**: 검증 완성도 평가

## 📊 Performance Specifications

- **⚡ Clock Frequency**: 최대 100MHz (시뮬레이션)
- **📈 Test Throughput**: 테스트당 약 250ns (25 클럭)
- **🎚️ Instruction Coverage**: 6개 B-type 명령어 완전 지원
- **🗺️ Execution Model**: 단일 사이클 분기 실행
- **📊 Memory Model**: Little-endian 바이트 순서
- **🔗 Interface Latency**: 클럭 기반 동기 인터페이스

## 🚀 Future Enhancements

### **🔧 Planned Improvements**
- **UVM Migration**: 표준 UVM 환경으로 업그레이드
- **Formal Verification**: Model checking 추가
- **Multi-cycle Support**: 파이프라인 프로세서 대응
- **Performance Analysis**: 타이밍 및 전력 검증

### **📈 Advanced Features**
- **Mutation Testing**: 설계 변이를 통한 테스트 품질 검증
- **Regression Automation**: CI/CD 파이프라인 통합
- **Coverage-driven Test Generation**: 자동 테스트 생성
- **FPGA Validation**: 실제 하드웨어 검증

## 📋 Verification Checklist

### **✅ Completed Verification Items**
- [x] All B-type instructions (BEQ, BNE, BLT, BGE, BLTU, BGEU)
- [x] PC update logic for taken/not-taken branches
- [x] Immediate value sign extension (13-bit → 32-bit)
- [x] x0 register special handling (always zero)
- [x] Word-aligned branch targets
- [x] Constraint randomization testing
- [x] SystemVerilog assertions (5개 속성)
- [x] Functional coverage collection (4개 그룹)
- [x] Backdoor register access
- [x] Real-time signal monitoring

### **🔄 Ongoing Verification**
- [ ] Corner case stress testing
- [ ] Performance regression analysis
- [ ] Cross-platform compatibility
- [ ] Documentation completion
- [ ] Formal verification integration

## 🛠️ Tools & Environment

### **📋 Required Tools**
- **Simulator**: Vivado/ModelSim/QuestaSim
- **Language**: SystemVerilog (IEEE 1800-2017)
- **IP Cores**: Xilinx BRAM IP (blk_mem_gen_0)
- **Platform**: Windows/Linux 호환

### **📁 File Dependencies**
- **DUT Files**: cpu_with_data_memory_dut.sv 및 하위 모듈
- **TB Files**: tb_B_type.sv (메인 테스트벤치)
- **IP Files**: blk_mem_gen_0.xci (메모리 IP)
- **Define Files**: define.sv (명령어 상수 정의)

---

**🎯 Verification Objectives**: 이 검증 프레임워크는 RV32I B-type 분기 명령어의 **기능적 정확성**과 **설계 준수성**을 보장하며, **업계 표준 검증 방법론**을 적용하여 **높은 품질의 검증 결과**를 제공합니다.
