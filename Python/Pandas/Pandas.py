import pandas as pd

# mydataset = {
#   'cars': ["BMW", "Volvo", "Ford"],
#   'passings': [3, 7, 2]
# }

# myvar = pd.DataFrame(mydataset)

# print(myvar)


a = [1, 7, 2]

myvar = pd.Series(a, index=["x", "y", "z"])

print(myvar)