def test_plink2treemix():
    assert plink2treemix(input_data1) == expected_output1
    assert plink2treemix(input_data2) == expected_output2
    assert plink2treemix(input_data3) == expected_output3