. C:\Users\carlo\OneDrive\Escritorio\FinalProjectSurvey\project.ps1
Describe "Metrics are correct" {
    It "Gets the right number of processors"{
        $allProcessors = (Get-WmiObject -Class Win32_Processor).NumberOfLogicalProcessors
        $Expected_Processor_Count = [uint32]12        
        $allProcessors | Should -Be $Expected_Processor_Count
    }
    It "Gets the right Organization"{
        $Organization = (Get-CimInstance -Class Win32_OperatingSystem | Select-object Organization).Organization
        $Expected_Name = "HP"
        $Organization | Should -Be $Expected_Name
    }
    It "Gets the rigth Version"{
        $Version = (Get-CimInstance -Class Win32_OperatingSystem | Select-object Version).Version
        $Expected_Name = "10.0.22621"
        $Version | Should -Be $Expected_Name
    }
    It "Gets the rigth Caption"{
        $Caption = (Get-CimInstance -Class Win32_OperatingSystem | Select-object Caption).Caption
        $Expected_Name = "Microsoft Windows 11 Home"
        $Caption | Should -Be $Expected_Name
    }
    It "Gets the rigth BuildNumber"{
        $BuildNumber = (Get-CimInstance -Class Win32_OperatingSystem | Select-object BuildNumber).BuildNumber
        $Expected_Name = 22621
        $BuildNumber | Should -Be $Expected_Name
    }
    It "Gets the rigth Manufacturer"{
        $Manufacturer = (Get-CimInstance -Class Win32_OperatingSystem | Select-object Manufacturer).Manufacturer
        $Expected_Name = "Microsoft Corporation"
        $Manufacturer | Should -Be $Expected_Name
    }
}

